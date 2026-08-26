from django.test import TestCase

from demo.views import AppStats

class AppStatsTest(TestCase):

    def test_initial_value(self):
        stats = AppStats()
        self.assertEqual(stats.view_count, 0)

    def test_increment(self):
        stats = AppStats()
        stats.increment()
        self.assertEqual(stats.view_count, 1)

    def test_multiple_increments(self):
        stats = AppStats()
        stats.increment()
        stats.increment()
        self.assertEqual(stats.view_count, 2)

