import unittest
import uuid

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
        ignore_severities_at_or_below = Severity('high')
        whitelist = Whitelist(ignore_severities_at_or_below)
        self.assertEqual(whitelist.ignore_severities_at_or_below, ignore_severities_at_or_below)


class VulnerabilityTestCase(unittest.TestCase):

    def test_cve_id(self):
        cve_id = uuid.uuid4().hex
        severity = uuid.uuid4().hex

        vulnerability = Vulnerability(cve_id, severity)

        self.assertEqual(vulnerability.cve_id, vulnerability.cve_id)
        self.assertEqual(vulnerability.severity, vulnerability.severity)

    def test_str(self):
        cve_id = uuid.uuid4().hex
        severity = uuid.uuid4().hex

        vulnerability = Vulnerability(cve_id, severity)

        self.assertEqual(str(vulnerability), cve_id)
