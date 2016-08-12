import json
import tempfile
import unittest

from ..io import read_whitelist
from ..io import read_vulnerabilities


class ReadWhitelistTestCase(unittest.TestCase):

    def test_ctr(self):
        filename = None
        whitelist = read_whitelist(filename)
        self.assertIsNotNone(whitelist)

    def test_filename_does_not_exist(self):
        filename = 'this file does not exist.json'
        whitelist = read_whitelist(filename)
        self.assertIsNone(whitelist)

    def test_invalid_json(self):
        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+') as fp:
            fp.write('{')
        whitelist = read_whitelist(temp_whitelist_filename.name)
        self.assertIsNone(whitelist)

    def test_happy_path(self):
        the_whitelist = {
            'ignoreSevertiesAtOrBelow': 'Low',
            'random': 'bindle',
        }
        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+') as fp:
            fp.write(json.dumps(the_whitelist))
        whitelist = read_whitelist(temp_whitelist_filename.name)
        self.assertIsNotNone(whitelist)
        self.assertIsNotNone(whitelist.whitelist)
        self.assertEqual(whitelist.whitelist, the_whitelist)


class ReadVulnerabilitiesTestCase(unittest.TestCase):

    def test_ctr(self):
        directory = None
        vulnerabilities = read_vulnerabilities(directory)
        self.assertIsNone(vulnerabilities)
