from django.core.files import File

from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from scipy.stats import gaussian_kde

from .mahalanobis import mahalanobis
from .models import Structure, TimeSeries, PowerSpectrum, NaturalFrequencies, StructurePermission, CableForce, Network, \
    StructurePosition, Position
from .serializers import StructureSerializer, TimeSeriesSerializer, NaturalFrequenciesSerializer, CableForceSerializer
from .taut_string import tension_forces
from .welch import calculate_welch_frequencies, align_multiple_streams, calculate_mean_welch_frequencies
from .code_ids import id_to_code, code_to_id

import logging
import numpy as np

log = logging.getLogger(__name__)


def index(request):
    return render(request, "core/index.html", {})


def structures(request):
    context = {
        "structures": Structure.objects.all()
    }
    return render(request, "core/structures.html", context)


class StructureList(generics.ListCreateAPIView):
    """
        Returns a json in the following format:

            [{ 'id': 1
              'name': 'structure ...',
              'count': 3  <<< number of readings in this structure
              },]
    """

    queryset = Structure.objects.all()
    serializer_class = StructureSerializer
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        response = super().get(request, *args, **kwargs)

        logger = logging.getLogger('django.request')
        logger.info(f"Getting structures for {request.user.id}")

        allowed_structure_ids = \
            [structure.structure_id for structure in StructurePermission.objects.filter(user_id=request.user.id)]

        response_original_obj = response.data
        response_obj = []
        for structure in response_original_obj:
            id = structure['id']
            if id in allowed_structure_ids:
                count = NaturalFrequencies.objects.filter(structure_id=id).count()
                response_obj.append({
                    'id': structure['id'],
                    'name': structure['name'],
                    'cable_mass': structure.get('cable_mass', 0.0),
                    'cable_length': structure.get('cable_length', 0.0),
                    'structure_type': structure.get('structure_type', 'structure'),
                    'count': count
                })

        return Response(data=response_obj, status=status.HTTP_200_OK)


class TimeSeriesList(generics.ListCreateAPIView):
    """
        Used to upload accelerometer readings and get its welch frequencies

        After uploading (via POST), returns a json in the following format:

            { 'mean': [0.0, 0.0, 0.0],  <-- mean freq1, freq2 and freq3 values from the history of this structure
              'frequencies': [0.0,0.123123,....],
              'x': [0.0,0.123123,....],
              'y': [0.0,0.123123,....],
              'z': [0.0,0.123123,....] }
    """

    queryset = TimeSeries.objects.all()
    serializer_class = TimeSeriesSerializer
    permission_classes = [IsAuthenticated]

    reading_id = -1

    # uncomment this to fine debug requests
    # def dispatch(self, request, *args, **kwargs):
    #     return super().dispatch(request, *args, **kwargs)

    def perform_create(self, serializer):
        super().perform_create(serializer)
        self.reading_id = int(serializer.data['id'])
        log.info("perform_create")

    def post(self, request, *args, **kwargs):
        super().post(request, *args, **kwargs)

        reading_db = TimeSeries.objects.get(pk=self.reading_id)
        structure_db = reading_db.structure

        # TODO check if request.user is able to to post information about this structure

        # convert the uploaded file into a list of lines
        file_obj = request.FILES['raw_file']
        lines = []
        for line in file_obj:
            lines.append(line.decode())

        frequencies_list, x_list, y_list, z_list = calculate_welch_frequencies(lines)

        power_spectrum_filename = f"power_spectrum_{self.reading_id}.csv"
        power_spectrum_filelocation = f"/tmp/{power_spectrum_filename}"
        with open(power_spectrum_filelocation, "w") as file:
            for idx in range(len(frequencies_list)):
                file.write(f"{frequencies_list[idx]};{x_list[idx]};{y_list[idx]};{z_list[idx]}\n")

        power_spectrum_db = PowerSpectrum(reading=reading_db, structure=structure_db)
        power_spectrum_db.raw_file.save(power_spectrum_filename, File(open(power_spectrum_filelocation)))
        power_spectrum_db.save()

        # calculate mean frequencies based on history
        history_frequencies = NaturalFrequencies.objects.filter(structure=structure_db)
        sum_f1, sum_f2, sum_f3 = 0, 0, 0
        for history_frequency in history_frequencies:
            sum_f1 += history_frequency.frequencies[0]
            sum_f2 += history_frequency.frequencies[1]
            sum_f3 += history_frequency.frequencies[2]

        size = len(history_frequencies) + 0.0

        if size == 0:
            mean = [0.0, 0.0, 0.0]
        else:
            mean = [sum_f1 / size, sum_f2 / size, sum_f3 / size]

        response_data = {'id': self.reading_id,
                         'mean': mean,
                         'frequencies': frequencies_list,
                         'x': x_list,
                         'y': y_list,
                         'z': z_list}

        return Response(data=response_data, status=status.HTTP_201_CREATED)


class NaturalFrequenciesList(generics.ListCreateAPIView):
    queryset = NaturalFrequencies.objects.all()
    serializer_class = NaturalFrequenciesSerializer
    permission_classes = [IsAuthenticated]

    current_frequencies = []

    # uncomment this to fine debug requests
    # def dispatch(self, request, *args, **kwargs):
    #     return super().dispatch(request, *args, **kwargs)

    def perform_create(self, serializer):
        super().perform_create(serializer)
        self.current_frequencies = serializer.data['frequencies']

    def post(self, request, *args, **kwargs):
        super().post(request, *args, **kwargs)

        structure_db = Structure.objects.get(pk=request.data['structure'])

        if request.data['training']:
            return Response(data={}, status=status.HTTP_201_CREATED)

        # TODO check if request.user is able to to post information about this structure

        all_natural_frequencies_db = NaturalFrequencies.objects.filter(structure_id=structure_db.id,
                                                                       training=True)

        # don't need to exclude the last one, since it was registered with training=False
        history_frequencies = [x.frequencies for x in all_natural_frequencies_db]
        assert len(history_frequencies) >= 4

        damage, ucl, history_points = mahalanobis(history_frequencies, self.current_frequencies)

        response_data = {'damage': damage, 'ucl': ucl, 'history': history_points}

        return Response(data=response_data, status=status.HTTP_201_CREATED)


class CableForceList(generics.ListCreateAPIView):
    queryset = CableForce.objects.all()
    serializer_class = CableForceSerializer
    permission_classes = [IsAuthenticated]

    def perform_create(self, serializer):
        super().perform_create(serializer)

    def post(self, request, *args, **kwargs):

        frequencies = request.data.get('frequencies', [])

        if not frequencies:
            return Response({'error': 'Frequencies not provided or empty.'}, status=status.HTTP_400_BAD_REQUEST)

        structure_db = Structure.objects.get(pk=request.data['structure'])
        force_freq1, force_freq2, force_freq3, cable_force = tension_forces(structure_db.cable_mass,
                                                                            structure_db.cable_length, frequencies)

        reading_db = TimeSeries.objects.get(pk=request.data['reading'])

        cable_force_db = CableForce(structure=structure_db, reading=reading_db, frequencies=frequencies,
                                    cable_force=cable_force, force_freq1=force_freq1, force_freq2=force_freq2,
                                    force_freq3=force_freq3,
                                    owner=request.user)
        cable_force_db.save()

        mean_forces = np.array(
            list(CableForce.objects.filter(structure=structure_db).values_list('cable_force', flat=True)))

        if len(mean_forces) < 5:
            return Response(data={'force_freq1': force_freq1, 'force_freq2': force_freq2, 'force_freq3': force_freq3,
                                  'cable_force': cable_force, 'count': len(mean_forces)},
                            status=status.HTTP_201_CREATED)


        # Verifica se os dados têm variância suficiente para KDE
        if np.var(mean_forces) == 0 or np.std(mean_forces) < 1e-10:
            return Response(data={'force_freq1': force_freq1, 'force_freq2': force_freq2, 'force_freq3': force_freq3,
                                  'cable_force': cable_force, 'count': len(mean_forces),
                                  'forces': mean_forces.tolist(), 'pdf': []},
                            status=status.HTTP_201_CREATED)

        kde = gaussian_kde(mean_forces)

        x_values = np.linspace(mean_forces.min(), mean_forces.max(), 9)
        x_values = np.append(x_values, cable_force)
        x_values = np.sort(x_values)
        pdf_values = kde(x_values)

        return Response(data={'force_freq1': force_freq1, 'force_freq2': force_freq2, 'force_freq3': force_freq3,
                              'cable_force': cable_force, 'count': len(mean_forces),
                              'forces': x_values.tolist(), 'pdf': pdf_values.tolist()},
                        status=status.HTTP_201_CREATED)


# create a Network with a valid structure
class CreateNetworkView(APIView):
    def post(self, request):
        structure_id = request.data.get('structureId')

        if not Structure.objects.filter(id=structure_id).exists():
            return Response({'error': 'Structure does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network_db = Network(
            master=request.user,
            structure=Structure.objects.get(id=request.data.get('structureId')),
        )
        network_db.save()
        return Response({'success': 'Network created', 'networkId': id_to_code(network_db.id)}, status=status.HTTP_201_CREATED)


# joins a Network that exists
class JoinNetworkView(APIView):
    # returns the position id that joined a Network
    def post(self, request):
        network_id_request = request.data.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)
        structure = network.structure
        structure_position = StructurePosition.objects.filter(
            structure=structure, location=request.data.get('location')
        ).first()

        if not structure_position:
            return Response({'error': 'Position not found.'}, status=status.HTTP_404_NOT_FOUND)

        if Position.objects.filter(network=network, structure_position=structure_position).exists():
            return Response({'error': 'Position occupied.'}, status=status.HTTP_404_NOT_FOUND)

        position = Position.objects.create(network=network, structure_position=structure_position, user=request.user)
        return Response({'join position id': position.id}, status=status.HTTP_200_OK)


# shows the info of a Network that exists
class NetworkInfoView(APIView):
    # returns information about each location, the number of stipulated positions and the number of connected positions
    def get(self, request):
        network_id_request = request.GET.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)
        structure_positions = StructurePosition.objects.filter(structure=network.structure)
        num_structure_positions = structure_positions.count()
        positions_connected = Position.objects.filter(network=network)
        num_positions = positions_connected.count()

        locations = []

        for structure_position in structure_positions:
            connected = False
            for position_connected in positions_connected:
                if position_connected.structure_position == structure_position:
                    connected = True
                    location_detail = {
                        'structure_position': {'position_location': structure_position.location, 'status': 'connected'},
                    }
                    locations.append(location_detail)
                    break

            if not connected:
                location_detail = {
                    'structure_position': {'position_location': structure_position.location, 'status': 'not connected'},
                }
                locations.append(location_detail)

        response_data = {
            'locations': locations,
            'structure_positions_count': num_structure_positions,
            'positions_count': num_positions
        }
        return Response(response_data, status=status.HTTP_200_OK)


# can get a Network status and update as well
class NetworkStatusView(APIView):
    # returns a current Network status
    def get(self, request):
        network_id_request = request.GET.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)

        return Response({'status': network.status}, status=status.HTTP_200_OK)

    # updates a Network status, and returns the status updated
    def post(self, request):
        network_id_request = request.data.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)
        status_network = request.data.get('status')
        network.status = status_network

        if status_network == 'reading':
            network.start_date = request.data.get('startDate')
        elif status_network == 'completed':
            network.end_date = request.data.get('endDate')

        network.save()
        return Response({'status': network.status}, status=status.HTTP_200_OK)


# the information about readings and allocate readings
class NetworkReadingsView(APIView):
    # returns information about each of the locations and whether they all have readings left or not ('completed' or 'pending')
    # if completed, returns the information to make a graphic
    def get(self, request):
        network_id_request = request.GET.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exist.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)
        positions_connected = Position.objects.filter(network=network)

        locations = []
        all_done = True
        readings = []

        for position_connected in positions_connected:
            if not position_connected.reading:
                locations.append({
                    'structure_position': {
                        'position_location': position_connected.structure_position.location,
                        'reading': 'pending'
                    }
                })
                all_done = False
            else:
                locations.append({
                    'structure_position': {
                        'position_location': position_connected.structure_position.location,
                        'reading': 'completed'
                    }
                })
                readings.append(position_connected.reading)

        response_data = {
            'locations': locations,
            'all_done': 'completed' if all_done else 'pending'
        }

        if all_done:
            multiple_lines = []
            for reading in readings:
                if reading and reading.raw_file:
                    with open(reading.raw_file.path, "r") as file:
                        lines = file.readlines()
                        print('lines:')
                        print(lines)
                        if not lines:
                            continue
                        multiple_lines.append(lines)

            if not multiple_lines:
                return Response({'error': 'No valid readings found.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            # calculate the avg_freq, avg_x, avg_y, avg_z of all devices
            avg_freq, avg_x, avg_y, avg_z = calculate_mean_welch_frequencies(align_multiple_streams(multiple_lines))

            # calculate mean natural frequencies
            readings_in_network = TimeSeries.objects.filter(position__network=network)
            history_frequencies = NaturalFrequencies.objects.filter(reading__in=readings_in_network)

            sum_f1, sum_f2, sum_f3 = 0, 0, 0
            for history_frequency in history_frequencies:
                sum_f1 += history_frequency.frequencies[0]
                sum_f2 += history_frequency.frequencies[1]
                sum_f3 += history_frequency.frequencies[2]

            history_frequencies = NaturalFrequencies.objects.filter(structure=network.structure)
            sum_f1, sum_f2, sum_f3 = 0, 0, 0
            for history_frequency in history_frequencies:
                sum_f1 += history_frequency.frequencies[0]
                sum_f2 += history_frequency.frequencies[1]
                sum_f3 += history_frequency.frequencies[2]

            size = len(history_frequencies) + 0.0

            if size == 0:
                mean = [0.0, 0.0, 0.0]
            else:
                mean = [sum_f1 / size, sum_f2 / size, sum_f3 / size]

            # add data to the response_data
            response_data.update({
                'mean': mean,
                'frequencies': avg_freq,
                'x': avg_x,
                'y': avg_y,
                'z': avg_z
            })

        return Response(response_data, status=status.HTTP_200_OK)

    # allocates a reading to a position, Network status must be completed
    def post(self, request):
        network_id_request = request.data.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)

        if not network.status == 'completed':
            return Response({'error': 'Network not completed, network is ' + network.status + '.'},
                            status=status.HTTP_400_BAD_REQUEST)

        structure_position = StructurePosition.objects.filter(structure=network.structure,
                                                              location=request.data.get('location')).first()
        reading_id = request.data.get('reading')
        position = Position.objects.filter(network=network, structure_position=structure_position).first()

        if not position:
            return Response({'error': 'Invalid position.'}, status=status.HTTP_400_BAD_REQUEST)

        time_series = TimeSeries.objects.filter(id=reading_id).first()

        if not time_series:
            return Response({'error': 'Invalid reading ID.'}, status=status.HTTP_400_BAD_REQUEST)

        position.reading = time_series
        position.save()
        return Response({'reading': 'Reading posted.'}, status=status.HTTP_201_CREATED)


# disconnects from a Network
class DisconnectNetworkView(APIView):
    # deletes the position from a Network and returns a location that got disconnected
    def post(self, request):
        network_id_request = request.data.get('networkId')
        network_id = code_to_id(network_id_request)

        if not Network.objects.filter(id=network_id).exists():
            return Response({'error': 'Network does not exists.'}, status=status.HTTP_404_NOT_FOUND)

        network = Network.objects.get(id=network_id)
        structure_position = StructurePosition.objects.filter(
            structure=network.structure, location=request.data.get('location')
        ).first()

        if not structure_position:
            return Response({'error': 'Position not found.'}, status=status.HTTP_404_NOT_FOUND)

        position = Position.objects.filter(network=network, structure_position=structure_position).first()
        if position:
            response_data = {
                'deleted position location': position.structure_position.location,
            }
            position.delete()
            return Response(response_data, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Position not found'}, status=status.HTTP_404_NOT_FOUND)

# deletes a Network
class DeleteNetworkView(APIView):
    def delete(self, request):
        network_id_request = request.data.get('networkId')
        network_id = code_to_id(network_id_request)

        try:
            network = Network.objects.get(id=network_id)
        except Network.DoesNotExist:
            return Response({'error': 'Network does not exist.'}, status=status.HTTP_404_NOT_FOUND)

        network.delete()

        response_data = {
            'deleted network': network_id_request,
        }
        return Response(response_data, status=status.HTTP_200_OK)
