import unittest

from ..taut_string import tension_forces


class TensionForceTestCase(unittest.TestCase):
    def test_TensionForce_1(self):
        f1, f2, f3, cf = tension_forces(148.1, 100.62, [1.237, 2.456, 3.700])
        self.assertEqual(9177, f1)
        self.assertEqual(9044, f2)
        self.assertEqual(9123, f3)
        self.assertEqual(9115, cf)

        f1, f2, f3, cf = tension_forces(148.1, 100.62, [1.261, 2.512, 3.780])
        self.assertEqual(9537, f1)
        self.assertEqual(9462, f2)
        self.assertEqual(9522, f3)
        self.assertEqual(9507, cf)

        f1, f2, f3, cf = tension_forces(148.1, 100.62, [1.314, 2.614, 3.906])
        self.assertEqual(10356, f1)
        self.assertEqual(10246, f2)
        self.assertEqual(10167, f3)
        self.assertEqual(10256, cf)

    def test_TensionForce_2(self):
        f1, f2, f3, cf  = tension_forces(148.1, 100.62, [1.256, 2.513, 3.781])
        self.assertEqual(9462, f1)
        self.assertEqual(9469, f2)
        self.assertEqual(9527, f3)
        self.assertEqual(9486, cf)

        f1, f2, f3, cf  = tension_forces(148.1, 100.62, [1.292, 2.580, 3.880])
        self.assertEqual(10012, f1)
        self.assertEqual(9981, f2)
        self.assertEqual(10032, f3)
        self.assertEqual(10008, cf)

        f1, f2, f3, cf  = tension_forces(148.1, 100.62, [1.302, 2.606, 3.909])
        self.assertEqual(10167, f1)
        self.assertEqual(10183, f2)
        self.assertEqual(10183, f3)
        self.assertEqual(10178, cf)

        f1, f2, f3, cf  = tension_forces(148.1, 100.62, [1.303, 2.618, 3.911])
        self.assertEqual(10183, f1)
        self.assertEqual(10277, f2)
        self.assertEqual(10193, f3)
        self.assertEqual(10218, cf)

    def test_TensionForce_3(self):
        f1, f2, f3, cf   = tension_forces(148.1, 100.62, [1.600, 3.219, 4.831])
        self.assertEqual(15354, f1)
        self.assertEqual(15537, f2)
        self.assertEqual(15553, f3)
        self.assertEqual(15481, cf)

        f1, f2, f3, cf   = tension_forces(148.1, 100.62, [1.658, 3.311, 5.003])
        self.assertEqual(16487, f1)
        self.assertEqual(16438, f2)
        self.assertEqual(16680, f3)
        self.assertEqual(16535, cf)

        f1, f2, f3, cf   = tension_forces(148.1, 100.62, [1.651, 3.315, 4.976])
        self.assertEqual(16348, f1)
        self.assertEqual(16477, f2)
        self.assertEqual(16501, f3)
        self.assertEqual(16442, cf)


if __name__ == '__main__':
    unittest.main()
