from import_export.formats.base_formats import Format
from io import BytesIO
from zipfile import ZipFile, ZIP_DEFLATED
import pathlib
from django.conf import settings


class ZIPFormat(Format):

    def get_title(self):
        return 'zip'

    def export_data(self, queryset):
        """
        Returns format representation for given dataset.
        """


        mf = BytesIO()
        with ZipFile(mf, "w", ZIP_DEFLATED, False) as zip_file:
            for file in queryset:
                zip_file.write(settings.MEDIA_ROOT / file[0], pathlib.PurePath(file[0]).name)
        # fix for Linux zip files read in Windows
        for file in zip_file.filelist:
            file.create_system = 0

        zip_file.close()
        mf.seek(0)

        return mf.read()

    def get_extension(self):
        """
        Returns extension for this format files.
        """
        return "zip"

    def can_export(self):
        return True