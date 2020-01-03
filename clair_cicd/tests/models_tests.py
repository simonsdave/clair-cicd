import unittest

from ..models import Severity
from ..models import Vulnerability
from ..models import Whitelist


class SeverityTestCase(unittest.TestCase):

    def test_str(self):
        severities_as_strs = [
            'medium',
            ' Medium',
            'high  ',
            'low',
            ' low  ',
        ]
        for severity_as_str in severities_as_strs:
            self.assertEqual(str(Severity(severity_as_str)), severity_as_str.strip().lower())

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


class VulnerabilityTestCase(unittest.TestCase):

    def test_ctr(self):
        vulnerability_dict = {}
        vulnerability = Vulnerability(vulnerability_dict)
        self.assertTrue(vulnerability_dict == vulnerability)

    def test_cve_id(self):
        cve_id = 'abc'
        vulnerability_dict = {
            'Name': cve_id,
        }
        vulnerability = Vulnerability(vulnerability_dict)
        self.assertTrue(cve_id == vulnerability.cve_id)

    def test_str(self):
        cve_id = 'abc'
        vulnerability_dict = {
            'Name': cve_id,
        }
        vulnerability = Vulnerability(vulnerability_dict)
        self.assertTrue(cve_id == str(vulnerability))

    def test_severity(self):
        severity = 'medium'
        vulnerability_dict = {
            'Severity': severity,
        }
        vulnerability = Vulnerability(vulnerability_dict)
        self.assertTrue(Severity(severity) == vulnerability.severity)
