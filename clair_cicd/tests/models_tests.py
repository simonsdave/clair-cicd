import unittest

from ..models import Severity

class SeverityTestCase(unittest.TestCase):

    def test_hash(self):
        severity = Severity('medium')
        hash(severity)

    def test_lt(self):
        self.assertTrue(Severity('medium') < Severity('high'))
        self.assertFalse(Severity('medium') < Severity('medium'))
        self.assertTrue(Severity('low') < Severity('high'))

    def test_le(self):
        self.assertTrue(Severity('medium') <= Severity('high'))
        self.assertTrue(Severity('medium') <= Severity('medium'))
        self.assertFalse(Severity('high') <= Severity('low'))
        self.assertTrue(Severity('low') <= Severity('high'))
