from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
import numpy.testing as npt

from ..models import Position, Structure, TimeSeries, NaturalFrequencies, StructurePermission, Network, \
    StructurePosition, PowerSpectrum
from ..code_ids import id_to_code, code_to_id


class StructuresViewTest(APITestCase):

    @classmethod
    def setUpTestData(cls):
        # Create 3 structures
        number_of_structures = 3

        for structure_id in range(number_of_structures):
            Structure.objects.create(
                name=f'Structure {structure_id}',
                structure_type=f'structure',
            )

        # criar uma structure cable

        # Create one user
        user = User.objects.create_user('test')

        # Give this user permission to the first two structures
        StructurePermission.objects.create(structure_id=1, user=user)
        StructurePermission.objects.create(structure_id=2, user=user)

    def test_get_structures(self):
        user = User.objects.get(username='test')
        self.client.force_authenticate(user=user)

        response = self.client.get(reverse('api-structures'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        expected = [
            {'id': 1, 'name': 'Structure 0', 'cable_mass': 0.0, 'cable_length': 0.0, 'structure_type': 'structure',
             'count': 0},
            {'id': 2, 'name': 'Structure 1', 'cable_mass': 0.0, 'cable_length': 0.0, 'structure_type': 'structure',
             'count': 0},
        ]
        self.assertEqual(response.data, expected)

    def test_post_structure(self):
        user = User.objects.get(username='test')
        self.client.force_authenticate(user=user)

        response = self.client.post(reverse('api-structures'), {'name': 'test'})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Structure.objects.count(), 4)
        self.assertEqual(Structure.objects.all()[3].name, 'test')


class ReadingsViewTest(APITestCase):

    @classmethod
    def setUpTestData(cls):
        # Create 2 structures
        number_of_structures = 2

        for structure_id in range(number_of_structures):
            Structure.objects.create(
                name=f'Structure {structure_id}',
            )

        # Create one user
        user = User.objects.create_user('test')

        # Give this user permission to the first two structures
        StructurePermission.objects.create(structure_id=1, user=user)
        StructurePermission.objects.create(structure_id=2, user=user)

    def test_post_reading(self):
        user = User.objects.get(username='test')
        self.client.force_authenticate(user=user)

        file = open("app4shm/apps/core/tests/sample_readings.txt", "r")
        response = self.client.post(reverse('api-readings'), {'structure': 1, 'raw_file': file})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['mean'], [0.0, 0.0, 0.0])
        self.assertEqual(len(response.data['frequencies']), 39),
        npt.assert_allclose(response.data['frequencies'][0:11],  # test only first 11 elements
                            [0.0,
                             0.6578947368421053,
                             1.3157894736842106,
                             1.973684210526316,
                             2.6315789473684212,
                             3.2894736842105265,
                             3.947368421052632,
                             4.605263157894737,
                             5.2631578947368425,
                             5.921052631578948,
                             6.578947368421053], rtol=1e-9)
        self.assertEqual(len(response.data['x']), 39),
        npt.assert_allclose(response.data['x'][0:11],  # test only first 11 elements
                            [0.5164033928994406,
                             1.0710240223392336,
                             0.1992937443609334,
                             0.09597083570256124,
                             0.021737085681951585,
                             0.038139956715548,
                             0.00840560825801945,
                             0.01900650981966371,
                             0.006116178076253484,
                             0.0099466889732733,
                             0.005426735941643766], rtol=1e-9)
        self.assertEqual(len(response.data['y']), 39),
        npt.assert_allclose(response.data['y'][0:11],  # test only first 11 elements
                            [0.297900543048553,
                             0.996218557935149,
                             0.2586782469475496,
                             0.10717045087383474,
                             0.03590425153898552,
                             0.03850035147295159,
                             0.015600002880287508,
                             0.01877364869684916,
                             0.009636578441134348,
                             0.010442608640709549,
                             0.006984272976279564])
        self.assertEqual(len(response.data['z']), 39),
        npt.assert_allclose(response.data['z'][0:11],  # test only first 11 elements
                            [2.4086356322049354e-31,
                             1.1706327136881534e-31,
                             5.773511339259508e-34,
                             4.609005178744885e-34,
                             1.8025416824147814e-34,
                             3.1661079322293718e-34,
                             2.9410130469940697e-34,
                             1.8304713934358005e-34,
                             4.3805671405745106e-34,
                             9.167658202626952e-34,
                             4.890536616496799e-34])


class FrequenciesViewTest(APITestCase):

    @classmethod
    def setUpTestData(cls):
        structure = Structure.objects.create(name=f'Structure 1')
        TimeSeries.objects.create(structure=structure)  # 1
        TimeSeries.objects.create(structure=structure)  # 2
        TimeSeries.objects.create(structure=structure)  # 3
        TimeSeries.objects.create(structure=structure)  # 4
        TimeSeries.objects.create(structure=structure)  # 5

        # Create one user
        user = User.objects.create_user('test')

        # Give this user permission to the first two structures
        StructurePermission.objects.create(structure_id=structure.id, user=user)

    def test_post_one_frequency_training(self):
        user = User.objects.get(username='test')
        self.client.force_authenticate(user=user)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1,
                                     'reading': 1,
                                     'frequencies': [1.0, 2.0, 3.0],
                                     'training': True}, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(NaturalFrequencies.objects.count(), 1)
        self.assertEqual(NaturalFrequencies.objects.all()[0].structure_id, 1)
        self.assertEqual(NaturalFrequencies.objects.all()[0].reading_id, 1)
        self.assertEqual(NaturalFrequencies.objects.all()[0].frequencies, [1.0, 2.0, 3.0])

    def test_post_several_frequencies_training_and_then_mahalanobis(self):
        user = User.objects.get(username='test')
        self.client.force_authenticate(user=user)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1, 'reading': 1, 'frequencies': [1.0, 2.0, 3.0],
                                     'training': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1, 'reading': 2, 'frequencies': [1.1, 2.1, 3.1],
                                     'training': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1, 'reading': 3, 'frequencies': [1.0, 2.0, 3.1],
                                     'training': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1, 'reading': 4, 'frequencies': [1.1, 2.0, 3.0],
                                     'training': True}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.post(reverse('api-frequencies'),
                                    {'structure': 1, 'reading': 5, 'frequencies': [1.1, 2.0, 3.0],
                                     'training': False}, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        self.assertTrue(response.data['damage'])
        self.assertEqual(response.data['ucl'], 7.8147)
        npt.assert_allclose(response.data['history'], [2.9999999999999916,
                                                       3.0000000000000098,
                                                       3.0000000000000093,
                                                       2.999999999999993,
                                                       2.999999999999993], rtol=1e-9)

# in this tests, the network.id needs to be coded,
# so the views can process it
class NetworkListViewTest(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user_master = User.objects.create_user(username="master", password="password123")

        cls.structure = Structure.objects.create(
            name="Test Structure",
            owner=cls.user_master,
            structure_type="Structure"
        )

        cls.network = Network.objects.create(
            master=cls.user_master,
            structure=cls.structure,
        )

        cls.structure_position = StructurePosition.objects.create(
            structure=cls.structure,
            location=10
        )
        cls.new_structure_position = StructurePosition.objects.create(
            structure=cls.structure,
            location=20
        )

        cls.position_20 = Position.objects.create(
            structure_position=cls.new_structure_position,
            network=cls.network,
            user=cls.user_master
        )

    def setUp(self):
        user_master = User.objects.get(username='master')
        self.client.force_authenticate(user_master)

    def test_create_network(self):
        data = {
            "structureId": self.structure.id
        }
        response = self.client.post(reverse("create-network"), data)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_join_network(self):
        data = {
            "networkId": id_to_code(self.network.id),
            "location": 10,
        }
        response = self.client.post(reverse("join-network"), data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("join position id", response.data)

    def test_get_network_info(self):
        data = {
            "networkId": id_to_code(self.network.id)
        }
        response = self.client.get(reverse("network-info"), data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("locations", response.data)
        self.assertIn("structure_positions_count", response.data)
        self.assertIn("positions_count", response.data)

    def test_disconnect_network(self):
        data = {
            "networkId": id_to_code(self.network.id),
            "location": 20
        }
        response = self.client.post(reverse("disconnect-network"), data)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("deleted position location", response.data)

    def test_delete_network(self):
        response = self.client.delete(reverse("delete-network"), {"networkId": id_to_code(self.network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

# in this tests, the network.id needs to be coded,
# so the views can process it
class ComplexNetworkFlowTest(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user_master = User.objects.create_user(username="master", password="password123")
        cls.user_device1 = User.objects.create_user(username="device1", password="password123")
        cls.user_device2 = User.objects.create_user(username="device2", password="password123")
        cls.user_device3 = User.objects.create_user(username="device3", password="password123")

        cls.structure = Structure.objects.create(
            name="Test Structure",
            owner=cls.user_master,
            structure_type="Structure"
        )

        cls.structure_position1 = StructurePosition.objects.create(structure=cls.structure, location=1)
        cls.structure_position2 = StructurePosition.objects.create(structure=cls.structure, location=2)
        cls.structure_position3 = StructurePosition.objects.create(structure=cls.structure, location=3)

    def setUp(self):
        self.client.force_authenticate(self.user_master)

    def test_complex_network_flow(self):
        # create the network
        response = self.client.post(reverse("create-network"), {"structureId": self.structure.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response_data = response.json()
        self.assertIn('networkId', response_data)
        network_id = response_data['networkId']

        network = Network.objects.get(id=code_to_id(network_id))

        # see how many positions are connected
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 0)

        # connect positions
        self.client.force_authenticate(self.user_device1)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 1})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.user_device2)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 2})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.user_device3)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 3})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # see how many positions are connected, must be all 3
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 3)

        # disconnect position 3
        self.client.force_authenticate(self.user_device3)
        response = self.client.post(reverse("disconnect-network"), {"networkId": id_to_code(network.id), "location": 3})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # see how many positions are connected, must be 2
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 2)
        self.assertEqual(response.data["structure_positions_count"], 3)

        # reconnect device3
        self.client.force_authenticate(self.user_device3)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 3})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # see how many positions are connected, must be all 3
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 3)

        # set the network status to reading
        self.client.force_authenticate(self.user_master)
        response = self.client.post(reverse("network-status"),
                                    {"networkId": id_to_code(network.id), "status": "reading", "startDate": "2025-03-21"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # start readings
        self.client.force_authenticate(self.user_device2)
        time_series1 = TimeSeries.objects.create(structure=network.structure, owner=self.user_device2)

        self.client.force_authenticate(self.user_device1)
        time_series2 = TimeSeries.objects.create(structure=network.structure, owner=self.user_device1)

        self.client.force_authenticate(self.user_device3)
        time_series3 = TimeSeries.objects.create(structure=network.structure, owner=self.user_device3)

        # set the network status to completed
        self.client.force_authenticate(self.user_master)
        response = self.client.post(reverse("network-status"),
                                    {"networkId": id_to_code(network.id), "status": "completed", "endDate": "2025-03-21"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "completed")

        # post readings after being completed
        self.client.force_authenticate(self.user_device2)
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 2, "reading": time_series1.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        self.client.force_authenticate(self.user_device1)
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 1, "reading": time_series2.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        self.client.force_authenticate(self.user_device3)
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 3, "reading": time_series3.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_network_flow_with_errors(self):
        # create the network with an invalid structureId
        response = self.client.post(reverse("create-network"), {"structureId": 999})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # create the network
        response = self.client.post(reverse("create-network"), {"structureId": self.structure.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response_data = response.json()
        self.assertIn('networkId', response_data)
        network_id = response_data['networkId']

        network = Network.objects.get(id=code_to_id(network_id))

        # join an invalid position
        self.client.force_authenticate(self.user_device1)
        response = self.client.post(reverse("join-network"), {"networkId": network.id, "location": 99})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # join a valid position
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 1})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # join an occupied position
        self.client.force_authenticate(self.user_device2)
        response = self.client.post(reverse("join-network"), {"networkId": network.id, "location": 1})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # disconnect an invalid position
        response = self.client.post(reverse("disconnect-network"), {"networkId": network.id, "location": 99})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # disconnect a position witch is not connected
        response = self.client.post(reverse("disconnect-network"), {"networkId": network.id, "location": 2})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # get the info of a network that does not exist
        response = self.client.get(reverse("network-info"), {"networkId": 999})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # get the status of a network that does not exist
        response = self.client.get(reverse("network-status"), {"networkId": 999})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # post the status of a network that does not exist
        response = self.client.post(reverse("network-status"), {"networkId": 999, "status": "reading"})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # post an invalid reading into the network
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 1, "reading": 999})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

        # readings not completed with an invalid networkId
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-readings"), {"networkId": 999})
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

# in this tests, the network.id needs to be coded,
# so the views can process it
class NetworkDiagramTest(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user_master = User.objects.create_user(username="master", password="password123")
        cls.user_device1 = User.objects.create_user(username="device1", password="password123")
        cls.user_device2 = User.objects.create_user(username="device2", password="password123")

        cls.structure = Structure.objects.create(
            name="Test Structure",
            owner=cls.user_master,
            structure_type="Structure"
        )

        cls.structure_position1 = StructurePosition.objects.create(structure=cls.structure, location=1)
        cls.structure_position2 = StructurePosition.objects.create(structure=cls.structure, location=2)
        cls.structure_position3 = StructurePosition.objects.create(structure=cls.structure, location=3)

    def setUp(self):
        self.client.force_authenticate(self.user_master)

    def test_diagram(self):
        # create the network
        response = self.client.post(reverse("create-network"), {"structureId": self.structure.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response_data = response.json()
        self.assertIn('networkId', response_data)
        network_id = response_data['networkId']

        network = Network.objects.get(id=code_to_id(network_id))

        # get network information
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 0)

        # join the network with the master according to the locations obtained above
        # a dropdown will appear in the application with the locations to choose one
        # master chooses location 1
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 1})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # get network information, now count must be 1
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 1)

        # on device1, join the network
        self.client.force_authenticate(self.user_device1)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 2})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # get network information, now count must be 2
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 2)

        # on device2, join the network
        self.client.force_authenticate(self.user_device2)
        response = self.client.post(reverse("join-network"), {"networkId": id_to_code(network.id), "location": 3})
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # get network information
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-info"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["positions_count"], 3)

        # check if it is waiting
        response = self.client.get(reverse("network-status"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "waiting")

        # update status to reading
        response = self.client.post(reverse("network-status"),
                                    {"networkId": id_to_code(network.id), "status": "reading", "startDate": "2025-03-21"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "reading")

        # start reading on all devices
        time_series1 = TimeSeries.objects.create(structure=network.structure, owner=self.user_master)

        self.client.force_authenticate(self.user_device1)
        time_series2 = TimeSeries.objects.create(structure=network.structure, owner=self.user_device1)

        self.client.force_authenticate(self.user_device2)
        time_series3 = TimeSeries.objects.create(structure=network.structure, owner=self.user_device2)

        # update status to completed
        self.client.force_authenticate(self.user_master)
        response = self.client.post(reverse("network-status"),
                                    {"networkId": id_to_code(network.id), "status": "completed", "endDate": "2025-03-21"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "completed")

        # master readings post
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 1, "reading": time_series1.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # get the readings and see which ones have already been allocated
        response = self.client.get(reverse("network-readings"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["all_done"], "pending")

        # post readings device1
        self.client.force_authenticate(self.user_device1)
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 2, "reading": time_series2.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        # get the readings and see which ones have already been allocated
        self.client.force_authenticate(self.user_master)
        response = self.client.get(reverse("network-readings"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["all_done"], "pending")

        # device2 readings post
        self.client.force_authenticate(self.user_device2)
        response = self.client.post(reverse("network-readings"),
                                    {"networkId": id_to_code(network.id), "location": 3, "reading": time_series3.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

# in this tests, the network.id needs to be coded,
# so the views can process it
class NetworkReadingsMultiUserTest(APITestCase):
    @classmethod
    def setUpTestData(cls):
        cls.user_device1 = User.objects.create_user(username='device1', password='password123')
        cls.user_device2 = User.objects.create_user(username='device2', password='password123')

        cls.structure = Structure.objects.create(
            name="Test Structure",
            owner=cls.user_device1,
            structure_type="Structure"
        )

    def test_network_readings_aggregation(self):
        self.client.force_authenticate(user=self.user_device1)
        # create the network
        response = self.client.post(reverse("create-network"), {"structureId": self.structure.id})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response_data = response.json()
        self.assertIn('networkId', response_data)
        network_id = response_data['networkId']

        network = Network.objects.get(id=code_to_id(network_id))

        structure_pos1 = StructurePosition.objects.create(structure=self.structure, location=1)
        structure_pos2 = StructurePosition.objects.create(structure=self.structure, location=2)

        position1 = Position.objects.create(network=network, structure_position=structure_pos1)
        position2 = Position.objects.create(network=network, structure_position=structure_pos2)

        # leitura dos ficheiros de cada dispositivo
        readings_d1 = open("app4shm/apps/core/tests/sample_readings_md_d1_lg.txt", "rb")
        readings_d2 = open("app4shm/apps/core/tests/sample_readings_md_d2_lg.txt", "rb")

        # depois da network estar completed, fazer post das rescpetivas readings
        response = self.client.post(
            reverse("api-readings"),
            {'structure': self.structure.id, 'raw_file': readings_d1},
            format='multipart'
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        readings_id1 = response.data["id"]

        response = self.client.post(reverse("api-readings"), {'structure': self.structure.id, 'raw_file': readings_d2}, format = 'multipart')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        readings_id2 = response.data["id"]

        # update status to completed
        response = self.client.post(reverse("network-status"),
                                    {"networkId": id_to_code(network.id), "status": "completed", "endDate": "2025-05-19"})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], "completed")

        # associar as readings a posições
        response = self.client.post(reverse("network-readings"), {"networkId": id_to_code(network.id), "location": 1, "reading": readings_id1})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["reading"], "Reading posted.")

        response = self.client.post(reverse("network-readings"), {"networkId": id_to_code(network.id), "location": 2, "reading": readings_id2})
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["reading"], "Reading posted.")

        # fazer get das readings
        response = self.client.get(reverse("network-readings"), {"networkId": id_to_code(network.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        # apartir daqeui fazer os testes
        # verifica se as localizacoes estao corretas e os estados das leituras
        self.assertEqual(len(data['locations']), 2)
        self.assertEqual(data['all_done'], 'completed')

        # verifica se as leituras foram alocadas (arrays nao vazios)
        self.assertIn('frequencies', data)
        self.assertIn('x', data)
        self.assertIn('y', data)
        self.assertIn('z', data)

        self.assertTrue(len(data['frequencies']) > 0)
        self.assertTrue(len(data['x']) > 0)
        self.assertTrue(len(data['y']) > 0)
        self.assertTrue(len(data['z']) > 0)