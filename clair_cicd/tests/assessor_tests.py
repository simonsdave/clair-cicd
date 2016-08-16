import uuid
import unittest

from ..models import Vulnerability
from ..assessor import VulnerabilitiesRiskAssessor
from ..models import Whitelist


class VulnerabilitiesRiskAssessorTestCase(unittest.TestCase):

    def test_ctr(self):
        whitelist = uuid.uuid4().hex
        vulnerabilities = uuid.uuid4().hex

        vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)

        self.assertEqual(whitelist, vra.whitelist)
        self.assertEqual(vulnerabilities, vra.vulnerabilities)

    def test_no_vulnerabilities_should_assess_clean(self):
        whitelist = Whitelist({})
        vulnerabilities = []

        vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)
        self.assertTrue(vra.assess())

    def test_medium_severity_vulnerabilities_should_assess_clean_by_default(self):
        whitelist = Whitelist({})
        vulnerabilities = [Vulnerability({'Severity': 'Medium'})]

        vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)
        self.assertTrue(vra.assess())

    def test_med_sev_vul_with_medium_sev_wl_should_assess_clean(self):
        whitelist = Whitelist({'ignoreSevertiesAtOrBelow': 'Medium'})
        vulnerabilities = [Vulnerability({'Severity': 'Medium'})]

        vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)
        self.assertTrue(vra.assess())

    def test_high_severity_vulnerabilities_should_assess_dirty(self):
        whitelist = Whitelist({})
        vulnerabilities = [Vulnerability({'Severity': 'High'})]

        vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)
        self.assertFalse(vra.assess())
