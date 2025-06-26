from django.core.management.base import BaseCommand

from ...models import TimeSeries, Structure, PowerSpectrum, NaturalFrequencies

import logging

log = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Cleans up all the readings associated with a given structure'

    def add_arguments(self, parser):
        parser.add_argument('structure', type=str, nargs=1, help='The name of the structure')

    def handle(self, *args, **options):
        structure_name = options['structure'][0]
        log.info(f'Starting cleanup of {structure_name}')

        try:
            structure_db = Structure.objects.get(name=structure_name)

            NaturalFrequencies.objects.filter(structure=structure_db).delete()
            PowerSpectrum.objects.filter(structure=structure_db).delete()
            TimeSeries.objects.filter(structure=structure_db).delete()

            log.info(f'Database cleanup of {structure_name} successful.')

        except Structure.DoesNotExist:
            log.info(f'{structure_name} doesn\'t exist.')


