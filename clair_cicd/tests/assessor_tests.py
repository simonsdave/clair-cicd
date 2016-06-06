import uuid
import unittest

from ..assessor import VulnerabilitiesRiskAssessor


class VulnerabilitiesRiskAssessorTestCase(unittest.TestCase):

    def test_ctr(self):
        verbose = uuid.uuid4().hex
        whitelist = uuid.uuid4().hex
        vulnerabilities = uuid.uuid4().hex

        vra = VulnerabilitiesRiskAssessor(verbose, whitelist, vulnerabilities)

        self.assertEqual(verbose, vra.verbose)
        self.assertEqual(whitelist, vra.whitelist)
        self.assertEqual(vulnerabilities, vra.vulnerabilities)
