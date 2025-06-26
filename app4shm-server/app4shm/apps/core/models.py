import os
import string, random

from django.core.exceptions import ValidationError
from django.conf import settings
from django.db import models


class Structure(models.Model):
    STRUCTURE_TYPES = [
        ('structure', 'Structure'),
        ('cable', 'Cable'),
    ]

    name = models.CharField(max_length=100, unique=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)
    structure_type = models.CharField(max_length=10, choices=STRUCTURE_TYPES, default='structure')
    cable_length = models.FloatField(null=True, blank=True, help_text="(meters)", default=0.0)
    cable_mass = models.FloatField(null=True, blank=True, help_text="(kilograms/meters)", default=0.0)

    def verify_type(self):
        # Make the fields mandatory, if it is a cable
        if self.structure_type == 'cable':
            if self.cable_length is None or self.cable_mass is None:
                raise ValidationError("Cable length and cable mass are required for cable structures.")

    def save(self, *args, **kwargs):
        # Calls the clean method before saving
        self.verify_type()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.id} - {self.name} ({self.structure_type})"


class StructurePermission(models.Model):
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="permission")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user} has access to {self.structure.name}"


class TimeSeries(models.Model):
    date = models.DateTimeField(auto_now_add=True)
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="time_series")
    raw_file = models.FileField(upload_to='raw_time_series', null=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)

    class Meta:
        verbose_name_plural = 'Time series'

    def structure_name(self):
        return self.structure.name

    def __str__(self):
        return f"{self.id} - {self.date.strftime('%x %X')} (structure: {self.structure.name})"


class PowerSpectrum(models.Model):
    reading = models.ForeignKey(TimeSeries, on_delete=models.PROTECT, related_name="power_spectrum")
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="power_spectrum")
    raw_file = models.FileField(upload_to='raw_power_spectrum', null=True)

    def structure_name(self):
        return self.structure.name

    def date(self):
        d = self.reading.date
        return d

    def __str__(self):
        return f"{self.reading.date.strftime('%x %X')} (structure: {self.structure.name})"


class NaturalFrequencies(models.Model):
    reading = models.ForeignKey(TimeSeries, on_delete=models.PROTECT, related_name="natural_frequencies")
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="natural_frequencies")
    frequencies = models.JSONField()  # [ freq1, freq2, freq3, ... ]
    training = models.BooleanField(null=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)

    class Meta:
        verbose_name_plural = 'Natural frequencies'

    def structure_name(self):
        return self.structure.name

    def date(self):
        return self.reading.date

    def __str__(self):
        return f"{self.reading.date.strftime('%x %X')} (structure: {self.structure.name}) : {self.frequencies} | Training: {self.training}"


class CableForce(models.Model):
    reading = models.ForeignKey(TimeSeries, on_delete=models.PROTECT, related_name="cable_force")
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="cable_force")
    frequencies = models.JSONField()  # [ freq1, freq2, freq3, ... ]
    cable_force = models.IntegerField(default=0)
    force_freq1 = models.IntegerField(default=0)
    force_freq2 = models.IntegerField(default=0)
    force_freq3 = models.IntegerField(default=0)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)

    class Meta:
        verbose_name_plural = 'Cable forces'

    def structure_name(self):
        return self.structure.name

    def date(self):
        return self.reading.date

    def __str__(self):
        return f"{self.reading.date.strftime('%x %X')} (structure: {self.structure.name}) : {self.frequencies} | Cable Force: {self.cable_force}"


class StructurePosition(models.Model):
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="structure_position")
    location = models.IntegerField(default=0, help_text="(meters)")


class Network(models.Model):
    STATUS_TYPES = [
        ('waiting', 'waiting'),
        ('reading', 'reading'),
        ('completed', 'completed'),
    ]

    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    master = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)
    structure = models.ForeignKey(Structure, on_delete=models.PROTECT, related_name="network")
    status = models.CharField(max_length=10, choices=STATUS_TYPES, default='waiting')


class Position(models.Model):
    reading = models.ForeignKey(TimeSeries, on_delete=models.PROTECT, related_name="position", null=True, blank=True)
    structure_position = models.ForeignKey(StructurePosition, on_delete=models.PROTECT, related_name="position")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True)
    network = models.ForeignKey(Network, on_delete=models.CASCADE, related_name="position")
