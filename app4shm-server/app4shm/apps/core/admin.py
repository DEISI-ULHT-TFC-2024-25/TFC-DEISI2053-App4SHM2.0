import codecs
import csv
from datetime import datetime
import io
from django.contrib import admin
from django.contrib.admin import SimpleListFilter
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.models import User, Group
from django.db.models.signals import post_migrate
from django.dispatch import receiver
from django.forms import forms, ChoiceField, FileField
from django.forms.utils import ErrorList
from django.shortcuts import redirect, render
from django.urls import path
from import_export.admin import ExportActionModelAdmin
from import_export.formats import base_formats
from import_export.formats.base_formats import CSV

from .models import Structure, TimeSeries, PowerSpectrum, NaturalFrequencies, StructurePermission, CableForce, \
    StructurePosition, Position, Network
from .resources import TimeSeriesResource, PowerSpectrumResource, NaturalFrequenciesResource
from .zipformat import ZIPFormat

class SemicolonCSV(CSV):
    def get_title(self):
        return "csv"

    def get_extension(self):
        return "csv"

    def get_writer_kwargs(self, **kwargs):
        # Retorna os argumentos para o csv.writer com o delimitador ';'
        return {'delimiter': ';'}

    def export_set(self, dataset, **kwargs):
        """
        Exports the dataset using csv.writer with delimiter ';'.
        """
        # Obtém os argumentos para o writer (neste caso, já com o 'delimiter' definido)
        writer_kwargs = self.get_writer_kwargs(**kwargs)
        output = io.StringIO()
        # Aqui forçamos a criação do writer com delimiter=';'
        writer = csv.writer(output, **writer_kwargs)

        # Se houver cabeçalhos no dataset, escreve-os
        if dataset.headers:
            writer.writerow(dataset.headers)

        # Escreve todas as linhas do dataset
        writer.writerows(dataset)

        return output.getvalue()

    def export_data(self, dataset, **kwargs):
        """
        Some versions call export_data instead of export_set.
        """
        return self.export_set(dataset, **kwargs)


class StructureFilter(SimpleListFilter):
    """
        This class makes that in the filter box only shows up the Structures that the request user has permission to.
    """
    title = 'Structure'
    parameter_name = 'structure'

    def lookups(self, request, model_admin):
        user = request.user
        structures = Structure.objects.filter(permission__user=user)
        return [(structure.id, structure.name) for structure in structures]

    def queryset(self, request, queryset):
        value = self.value()
        if value:
            return queryset.filter(structure__id=value)


class CustomGroupAdmin(admin.ModelAdmin):
    pass  # Move group creation logic to the signal below


@receiver(post_migrate)
def create_app_group(sender, **kwargs):
    """
    Ensures the 'APP' group and its permissions are created after migrations.
    """
    from django.contrib.auth.models import Group, Permission

    if not Group.objects.filter(name='APP').exists():
        app_group = Group.objects.create(name='APP')

        # Get the view and delete permissions for YourModel
        add_permission_structure = Permission.objects.get(
            content_type__app_label='core',
            codename='add_structure'
        )

        view_permission_structure = Permission.objects.get(
            content_type__app_label='core',
            codename='view_structure'
        )

        view_permission_timeseries = Permission.objects.get(
            content_type__app_label='core',
            codename='view_timeseries'
        )

        delete_permission_timeseries = Permission.objects.get(
            content_type__app_label='core',
            codename='delete_timeseries'
        )

        view_permission_powerspectrum = Permission.objects.get(
            content_type__app_label='core',
            codename='view_powerspectrum'
        )

        delete_permission_powerspectrum = Permission.objects.get(
            content_type__app_label='core',
            codename='delete_powerspectrum'
        )

        view_permission_naturalfrequencies = Permission.objects.get(
            content_type__app_label='core',
            codename='view_naturalfrequencies'
        )

        delete_permission_naturalfrequencies = Permission.objects.get(
            content_type__app_label='core',
            codename='delete_naturalfrequencies'
        )

        app_group.permissions.add(
            add_permission_structure, view_permission_structure,
            view_permission_timeseries, delete_permission_timeseries,
            view_permission_powerspectrum, delete_permission_powerspectrum,
            view_permission_naturalfrequencies, delete_permission_naturalfrequencies,
        )


class CustomUserAdmin(UserAdmin):
    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)

        if not change:
            obj.is_staff = True
            obj.groups.add(Group.objects.get(name='APP'))
        super().save_model(request, obj, form, change)


class StructureAdmin(admin.ModelAdmin):
    def get_list_display(self, request):
        if request.user.groups.filter(name='APP').exists():
            return ("id", "name", "structure_type")
        else:
            return ("id", "name", "owner", "structure_type")

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(permission__user=request.user)

    def save_model(self, request, obj, form, change):
        """
        Saves the structure created. And links the structure with the user that created it.
        """
        obj.owner = request.user
        obj.save()
        structure_permission = StructurePermission(structure=obj, user=request.user)
        structure_permission.save()

    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields


class StructurePermissionAdmin(admin.ModelAdmin):
    list_display = ("structure", "user")

    def save_model(self, request, obj, form, change):
        """
        Creates the StructurePermission Object
        """
        obj.save()


class TimeSeriesAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_list_display(self, request):
        if request.user.groups.filter(name='APP').exists():
            return ("id", "date", "structure_name")
        else:
            return ("id", "date", "structure_name", "owner")

    def get_list_filter(self, request):
        if request.user.groups.filter(name='APP').exists():
            return (StructureFilter,)
        else:
            return ("structure",)

    resource_class = TimeSeriesResource

    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

    def get_export_formats(self):
        """
        Returns available import formats.
        """
        formats = (ZIPFormat, )
        return [f for f in formats if f().can_export()]

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields


class PowerSpectrumAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    list_display = ("reading_id", "date", "structure_name")

    def get_list_filter(self, request):
        if request.user.groups.filter(name='APP').exists():
            return (StructureFilter,)
        else:
            return ("structure",)

    search_fields = ("reading__id",)
    search_help_text = "Search for a specific READING ID"
    resource_class = PowerSpectrumResource

    def get_export_formats(self):
        """
        Returns available import formats.
        """
        formats = (ZIPFormat,)
        return [f for f in formats if f().can_export()]

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)


class CsvImportForm(forms.Form):
    structure = ChoiceField(choices=())
    csv_file = FileField()

    def __init__(self, structures, data=None, files=None, auto_id='id_%s', prefix=None, initial=None, error_class=ErrorList,
                 label_suffix=None, empty_permitted=False, field_order=None, use_required_attribute=None,
                 renderer=None):
        super().__init__(data, files, auto_id, prefix, initial, error_class, label_suffix, empty_permitted, field_order,
                         use_required_attribute, renderer)
        self.fields['structure'].choices = structures



class NaturalFrequenciesAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_list_display(self, request):
        if request.user.groups.filter(name='APP').exists():
            return ("reading_id", "date", "structure_name", "frequencies", "training")
        else:
            return ("reading_id", "date", "structure_name", "frequencies", "owner", "training")

    def get_list_filter(self, request):
        if request.user.groups.filter(name='APP').exists():
            return (StructureFilter,)
        else:
            return ("structure",)

    search_fields = ("reading__id", )
    search_help_text = "Search for a specific READING ID"
    resource_class = NaturalFrequenciesResource
    change_list_template = "core/natural_frequencies_changelist.html"


    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

    def get_export_formats(self):
        formats = (
            SemicolonCSV,  # CSV with delimiter ;
            base_formats.XLS,
            base_formats.XLSX,
        )
        return [f for f in formats if f().can_export()]


    def get_urls(self):
        urls = super().get_urls()
        my_urls = [
            path('import-csv/', self.import_csv),
        ]
        return my_urls + urls

    def import_csv(self, request):
        if request.method == "POST":
            structure_id = request.POST["structure"]
            structure_db = Structure.objects.get(pk=structure_id)
            csv_file = request.FILES["csv_file"]
            # some csv files are stored with an initial \ufeff character. that's why we use utf-8-sig instead of utf-8
            # see https://www.tutorialexample.com/fix-uufeff-invalid-character-when-reading-file-in-python-python-tutorial/
            reader = csv.reader(io.TextIOWrapper(csv_file, encoding='utf-8-sig'), delimiter=';')
            count = 0
            for row in reader:
                #Skip empty lines or lines with less than 4 columns
                if not row or len(row) < 4:
                    continue

                    # If there is a header, skip it (for example, if the first cell is "date")
                if row[0].strip().lower() == "date":
                    continue
                date_str = row[0].strip()
                # Converte as três frequências
                try:
                    freq1 = float(row[1].strip())
                    freq2 = float(row[2].strip())
                    freq3 = float(row[3].strip())
                except ValueError:
                    # If any conversion fails, you can skip the line or record an error
                    continue
                # Cria o TimeSeries com a data indicada
                timeSeries_db = TimeSeries(structure=structure_db)
                timeSeries_db.save()
                timeSeries_db.date = datetime.strptime(date_str, '%Y-%m-%d %H:%M:%S')
                timeSeries_db.save()
                # Cria NaturalFrequencies com os três valores e training=True
                naturalFreq_db = NaturalFrequencies(
                    reading=timeSeries_db,
                    structure=structure_db,
                    frequencies=[freq1, freq2, freq3],
                    training=True,
                    owner = request.user
                )
                naturalFreq_db.save()
                count += 1

            self.message_user(request,
                              "Your csv file has been imported. %s natural frequencies added to the database." % count)
            return redirect("..")

        structures_db = Structure.objects.all()
        structures = map(lambda s: (s.id, s.name), structures_db)
        form = CsvImportForm(structures)
        payload = {"form": form}
        return render(
            request, "core/natural_frequencies_upload_csv.html", payload
        )

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields

class CableForceAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

class StructurePositionAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

class PositionAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

class NetworkAdmin(ExportActionModelAdmin, admin.ModelAdmin):
    def get_fields(self, request, obj=None):
        fields = super().get_fields(request, obj)
        if request.user.groups.filter(name='APP').exists():
            fields = [field for field in fields if field != 'owner']
        return fields

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(structure__permission__user=request.user)

    def add_view(self, request, form_url='', extra_context=None):
        data = request.GET.copy()
        if not data.get('owner') and request.user.is_superuser:
            data['owner'] = str(request.user.id)
            request.GET = data
        return super().add_view(request, form_url, extra_context)

admin.site.register(Structure, StructureAdmin)
admin.site.register(TimeSeries, TimeSeriesAdmin)
admin.site.register(PowerSpectrum, PowerSpectrumAdmin)
admin.site.register(NaturalFrequencies, NaturalFrequenciesAdmin)
admin.site.register(StructurePermission, StructurePermissionAdmin)
admin.site.register(CableForce, CableForceAdmin)
admin.site.register(StructurePosition, StructurePositionAdmin)
admin.site.register(Position, PositionAdmin)
admin.site.register(Network, NetworkAdmin)
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)
admin.site.unregister(Group)
admin.site.register(Group, CustomGroupAdmin)


admin.site.site_header = "App4SHM Admin"
admin.site.site_title = "App4SHM Admin Portal"
admin.site.index_title = "Welcome to App4SHM Admin Portal"
