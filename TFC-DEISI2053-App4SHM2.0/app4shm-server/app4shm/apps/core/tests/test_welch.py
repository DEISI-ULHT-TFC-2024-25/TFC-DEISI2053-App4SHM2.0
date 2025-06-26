import unittest

import numpy as np
import numpy.testing as npt

from ..welch import calculate_welch_frequencies, interpolate_data_stream_aligned, parse_lines_to_readings, \
    align_multiple_streams, calculate_mean_welch_frequencies, readings_to_lines, calculate_welch_from_array


class ReadingDTO:
    def __init__(self, timestamp, x, y, z):
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z


class WelchTestCase(unittest.TestCase):
    def test_calculate_welch_frequencies(self):

        f = open("app4shm/apps/core/tests/sample_readings.txt", "r")
        frequencies_list, x_list, y_list, z_list = calculate_welch_frequencies(f.readlines())
        f.close()

        self.assertEqual(39, len(frequencies_list))
        self.assertEqual(39, len(x_list))
        self.assertEqual(39, len(y_list))
        self.assertEqual(39, len(z_list))

    def test_interpolate_data_stream_aligned_d1(self):
        with open("app4shm/apps/core/tests/sample_readings_md_d1.txt", "r") as f:
            data_stream = parse_lines_to_readings(f)

        interpolated = interpolate_data_stream_aligned(data_stream)

        expected_lines = """
        1642776059260;-5.1630707;7.9308043;2.5847285
        1642776059280;-5.1630707;7.9308043;2.5847285
        1642776059300;-5.1630707;7.9308043;2.5847285
        1642776059320;-5.1630707;7.9308043;2.5847285
        1642776059340;-4.854818;8.123172;2.5847285
        1642776059360;-4.854818;8.123172;2.5847285
        1642776059380;-4.854818;8.123172;2.5847285
        1642776059400;-4.854818;8.123172;2.5847285
        1642776059420;-4.854818;8.123172;2.5847285
        1642776059440;-4.854818;8.123172;2.5847285
        1642776059460;-4.854818;8.123172;2.5847285
        """.strip().splitlines()

        expected_data = parse_lines_to_readings(expected_lines)

        # compara interpolado vs esperado
        self.assertEqual(len(interpolated), len(expected_data))

        for inter, expected in zip(interpolated, expected_data):
            self.assertAlmostEqual(inter.timestamp, expected.timestamp, msg=expected.timestamp)
            self.assertAlmostEqual(inter.x, expected.x, msg=expected.timestamp)
            self.assertAlmostEqual(inter.y, expected.y, msg=expected.timestamp)
            self.assertAlmostEqual(inter.z, expected.z, msg=expected.timestamp)

    def test_interpolate_data_stream_aligned_d2(self):
        with open("app4shm/apps/core/tests/sample_readings_md_d2.txt", "r") as f:
            data_stream = parse_lines_to_readings(f)

        interpolated = interpolate_data_stream_aligned(data_stream)

        expected_lines = """
        1642776059240;-5.1745055;7.8308043;2.6947285
        1642776059260;-5.1745055;7.8308043;2.6947285
        1642776059280;-5.1745055;7.8308043;2.6947285
        1642776059300;-5.1745055;7.8308043;2.6947285
        1642776059320;-5.1745055;7.8308043;2.6947285
        1642776059340;-5.1745055;7.8308043;2.6947285
        1642776059360;-5.1745055;7.8308043;2.6947285
        1642776059380;4.954818;8.223172;2.4847285
        1642776059400;4.954818;8.223172;2.4847285
        1642776059420;4.954818;8.223172;2.4847285
        1642776059440;4.954818;8.223172;2.4847285
        """.strip().splitlines()

        expected_data = parse_lines_to_readings(expected_lines)

        # compara interpolado vs esperado
        self.assertEqual(len(interpolated), len(expected_data))

        for inter, expected in zip(interpolated, expected_data):
            self.assertAlmostEqual(inter.timestamp, expected.timestamp, msg=expected.timestamp)
            self.assertAlmostEqual(inter.x, expected.x, msg=expected.timestamp)
            self.assertAlmostEqual(inter.y, expected.y, msg=expected.timestamp)
            self.assertAlmostEqual(inter.z, expected.z, msg=expected.timestamp)

    def test_align_multiple_streams(self):
        multiple_lines = []
        with open("app4shm/apps/core/tests/sample_readings_md_d1.txt", "r") as file:
            lines = file.readlines()
            multiple_lines.append(lines)

        with open("app4shm/apps/core/tests/sample_readings_md_d2.txt", "r") as file:
            lines = file.readlines()
            multiple_lines.append(lines)

        # usar a função cirada
        avg_freq, avg_x, avg_y, avg_z = calculate_mean_welch_frequencies(align_multiple_streams(multiple_lines))

        # calcular a média manualmente
        avg_freq_exp = [0.0, 16.666666666666668]
        avg_x_exp = [0.03565910218566304, 0.11410912699412172]
        avg_y_exp = [6.630477222450696e-05, 0.00021217527111842252]
        avg_z_exp = [1.531249999999997e-05, 4.8999999999999965e-05]

        # comparar a função criada com a media calculada manualmente
        self.assertTrue(np.allclose(avg_freq_exp, avg_freq, atol=1e-2))
        self.assertTrue(np.allclose(avg_x_exp, avg_x, atol=1e-5))
        self.assertTrue(np.allclose(avg_y_exp, avg_y, atol=1e-5))
        self.assertTrue(np.allclose(avg_z_exp, avg_z, atol=1e-6))


if __name__ == '__main__':
    unittest.main()
