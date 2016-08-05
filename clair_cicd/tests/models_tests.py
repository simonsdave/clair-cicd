import unittest

from ..models import Severity
from ..models import Whitelist


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

    def test_eq(self):
        self.assertTrue(Severity('medium') == Severity('medium'))
        self.assertFalse(Severity('high') == Severity('low'))

    def test_ne(self):
        self.assertTrue(Severity('high') != Severity('low'))
        self.assertFalse(Severity('high') != Severity('high'))


class WhitelistTestCase(unittest.TestCase):

    def test_ctr(self):
        wl = {}
        whitelist = Whitelist(wl)
        self.assertTrue(whitelist.whitelist == wl)

    def test_default_ignore_severties_at_or_below(self):
        whitelist = Whitelist({})
        self.assertTrue(whitelist.ignore_severties_at_or_below == Severity('medium'))
