# serializers used by the Django Rest Framework
from rest_framework import serializers
from .models import Structure, TimeSeries, NaturalFrequencies, CableForce
from rest_framework.exceptions import ValidationError

class StructureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Structure
        fields = ('id', 'name', 'structure_type', 'cable_length', 'cable_mass')


class TimeSeriesSerializer(serializers.ModelSerializer):
    class Meta:
        model = TimeSeries
        fields = ('id', 'date', 'structure', 'raw_file')

    def create(self, validated_data):
        # Access the authenticated user
        user = self.context['request'].user
        validated_data['owner'] = user

        return super().create(validated_data)


class NaturalFrequenciesSerializer(serializers.ModelSerializer):
    class Meta:
        model = NaturalFrequencies
        fields = ('id', 'structure', 'reading', 'frequencies', 'training')

    def create(self, validated_data):
        # Access the authenticated user
        user = self.context['request'].user
        validated_data['owner'] = user

        return super().create(validated_data)

class CableForceSerializer(serializers.ModelSerializer):
    class Meta:
        model = CableForce
        fields = ('id', 'structure', 'reading', 'frequencies', 'cable_force')
        read_only_fields = ('cable_force',)


    def create(self, validated_data):
        frequencies = validated_data.get('frequencies')
        print(f"[DEBUG - Serializer] Frequências recebidas: {frequencies}")
        if not frequencies:
            raise ValidationError("Frequências não fornecidas ou vazias.")
        # Access the authenticated user
        user = self.context['request'].user
        validated_data['owner'] = user

        return super().create(validated_data)