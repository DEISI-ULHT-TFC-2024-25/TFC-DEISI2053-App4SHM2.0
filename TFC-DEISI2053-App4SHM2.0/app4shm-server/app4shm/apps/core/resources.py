from import_export import resources, fields
from import_export.widgets import DateWidget
from .models import TimeSeries, NaturalFrequencies, PowerSpectrum, CableForce

class NaturalFrequenciesResource(resources.ModelResource):
    # Campo para a data, extraído do objeto TimeSeries (assumindo que NaturalFrequencies.reading está definido)
    date = fields.Field(
        column_name='date',
        attribute='reading__date',
        widget=DateWidget(format='%Y-%m-%d %H:%M:%S')
    )
    # Campos para cada uma das três frequências
    frequency1 = fields.Field(column_name='frequency1')
    frequency2 = fields.Field(column_name='frequency2')
    frequency3 = fields.Field(column_name='frequency3')

    class Meta:
        model = NaturalFrequencies
        # Exporta os quatro campos na ordem desejada
        fields = ('date', 'frequency1', 'frequency2', 'frequency3')
        export_order = ('date', 'frequency1', 'frequency2', 'frequency3')

    def dehydrate_date(self, obj):
        """Retorna a data formatada ou vazio se não estiver definida."""
        if obj.reading and obj.reading.date:
            return obj.reading.date.strftime('%Y-%m-%d %H:%M:%S')
        return ''

    def dehydrate_frequency1(self, obj):
        try:
            return obj.frequencies[0]
        except (IndexError, TypeError):
            return ''

    def dehydrate_frequency2(self, obj):
        try:
            return obj.frequencies[1]
        except (IndexError, TypeError):
            return ''

    def dehydrate_frequency3(self, obj):
        try:
            return obj.frequencies[2]
        except (IndexError, TypeError):
            return ''

class TimeSeriesResource(resources.ModelResource):
    class Meta:
        model = TimeSeries
        fields = ('raw_file', )

class PowerSpectrumResource(resources.ModelResource):
    class Meta:
        model = PowerSpectrum
        fields = ('raw_file', )

class CableForceResource(resources.ModelResource):
    date = fields.Field(
        column_name='date',
        attribute='reading__date',
        widget=DateWidget(format='%Y-%m-%d %H:%M:%S')
    )
    structure_name = fields.Field(column_name='structure_name')
    frequency1 = fields.Field(column_name='frequency1')
    frequency2 = fields.Field(column_name='frequency2')
    frequency3 = fields.Field(column_name='frequency3')
    cable_force = fields.Field(column_name='cable_force')

    class Meta:
        model = CableForce
        fields = ('date', 'structure_name', 'frequency1', 'frequency2', 'frequency3', 'cable_force')
        export_order = ('date', 'structure_name', 'frequency1', 'frequency2', 'frequency3', 'cable_force')

    def dehydrate_date(self, obj):
        return obj.date().strftime('%Y-%m-%d %H:%M:%S') if obj.date() else ''

    def dehydrate_structure_name(self, obj):
        return obj.structure_name()

    def dehydrate_frequency1(self, obj):
        try:
            return obj.frequencies[0]
        except (IndexError, TypeError):
            return ''

    def dehydrate_frequency2(self, obj):
        try:
            return obj.frequencies[1]
        except (IndexError, TypeError):
            return ''

    def dehydrate_frequency3(self, obj):
        try:
            return obj.frequencies[2]
        except (IndexError, TypeError):
            return ''