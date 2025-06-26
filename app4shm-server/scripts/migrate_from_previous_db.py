from app4shm.apps.core.models import Structure, TimeSeries, NaturalFrequencies
# from apps.core.models import Structure, TimeSeries, NaturalFrequencies
from datetime import datetime
import csv

def run():

    # Baloico
    s1 = Structure(name="Baloico")
    s1.save()

    # passagemRigidaCG
    s2 = Structure(name='passagemRigidaCG')
    s2.save()

    # Itacaiunas Nova E5
    s3 = Structure(name='Itacaiunas Nova E5')
    s3.save()

    # Itacaiunas Nova E2
    s4 = Structure(name='Itacaiunas Nova E2')
    s4.save()

    # Itacaiunas Velha E2
    s5 = Structure(name='Itacaiunas Velha E2')
    s5.save()

    # Itacaiunas velha E5
    s6 = Structure(name='Itacaiunas velha E5')
    s6.save()

    # passagemFlexivelCG
    s7 = Structure(name='passagemFlexivelCG')
    s7.save()

    # PassagemFlexivelDano
    s8 = Structure(name='PassagemFlexivelDano')
    s8.save()

    with open('./scripts/app4shm_db.csv') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=',')
        line_count = 1
        next(csv_reader)
        next(csv_reader)

        for row in csv_reader:

            date_format = datetime.strptime('{} {}'.format(row[1], row[2]), '%Y-%m-%d %H:%M:%S')

            if row[6] == 'Baloico':
                t1 = TimeSeries(structure=s1)
                t1.save()
                t1.date = date_format
                t1.save()
                f1 = NaturalFrequencies(reading=t1, structure=s1, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f1.save()
                print(t1.date)

            elif row[6] == 'passagemRigidaCG':
                t2 = TimeSeries(structure=s2)
                t2.save()
                t2.date = date_format
                t2.save()
                f2 = NaturalFrequencies(reading=t2, structure=s2, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f2.save()
                print(t2.date)

            elif row[6] == 'Itacaiunas Nova E5':
                t3 = TimeSeries(structure=s3)
                t3.save()
                t3.date = date_format
                t3.save()
                f3 = NaturalFrequencies(reading=t3, structure=s3, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f3.save()
                print(t3.date)

            elif row[6] == 'Itacaiunas Nova E2':
                t4 = TimeSeries(structure=s4)
                t4.save()
                t4.date = date_format
                t4.save()
                f4 = NaturalFrequencies(reading=t4, structure=s4, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f4.save()
                print(t4.date)

            elif row[6] == 'Itacaiunas Velha E2':
                t5 = TimeSeries(structure=s5)
                t5.save()
                t5.date = date_format
                t5.save()
                f5 = NaturalFrequencies(reading=t5, structure=s5, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f5.save()
                print(t5.date)

            elif row[6] == 'Itacaiúnas velha E5':
                t6 = TimeSeries(structure=s6)
                t6.save()
                t6.date = date_format
                t6.save()
                f6 = NaturalFrequencies(reading=t6, structure=s6, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f6.save()
                print(t6.date)

            elif row[6] == 'passagemFlexivelCG':
                t7 = TimeSeries(structure=s7)
                t7.save()
                t7.date = date_format
                t7.save()
                f7 = NaturalFrequencies(reading=t7, structure=s7, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f7.save()
                print(t7.date)

            elif row[6] == 'PassagemFlexivelDano':
                t8 = TimeSeries(structure=s8)
                t8.save()
                t8.date = date_format
                t8.save()
                f8 = NaturalFrequencies(reading=t8, structure=s8, frequencies=[float(row[3]), float(row[4]), float(row[5])])
                f8.save()
                print(t8.date)

            line_count += 1
        print(line_count)

    # t = TimeSeries(structure=s)
    # t.save()
    # t.date = datetime.strptime('21-01-01 11:00:00','%y-%m-%d %H:%M:%S')
    # t.save()
    # f = NaturalFrequencies(reading=t, structure=s, frequencies='[1.0453,1.74216,2.78746]')
    # f.save()
    #
    # t = TimeSeries(structure=s)
    # t.save()
    # t.date = datetime.strptime('21-01-02 11:00:00','%y-%m-%d %H:%M:%S')
    # t.save()
    # f = NaturalFrequencies(reading=t, structure=s, frequencies='[0.981997,1.96399,2.94599]')
    # f.save()