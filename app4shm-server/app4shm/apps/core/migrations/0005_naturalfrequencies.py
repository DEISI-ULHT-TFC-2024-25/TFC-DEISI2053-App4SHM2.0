# Generated by Django 4.0 on 2022-02-07 09:46

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0004_welchfrequency'),
    ]

    operations = [
        migrations.CreateModel(
            name='NaturalFrequencies',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('frequencies', models.JSONField()),
                ('reading', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='natural_frequencies', to='core.reading')),
                ('structure', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='natural_frequencies', to='core.structure')),
            ],
        ),
    ]
