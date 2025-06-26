import unittest

from ..mahalanobis import mahalanobis


class MahalanobisTestCase(unittest.TestCase):
    def test_mahalanobis(self):
        damage, new_point, history_points = mahalanobis([[1.36886, 1.82648, 2.73973],
                                                         [1.06383, 4.25532, 6.38298],
                                                         [1.33345, 4.05, 8.88],
                                                         [1.2345, 3.456567, 7.343488]],
                                                        [8.88888, 11.11111, 13.33333])

        self.assertEqual(False, damage)
        self.assertEqual(7.8147, new_point)
        self.assertEqual(5, len(history_points))


if __name__ == '__main__':
    unittest.main()
