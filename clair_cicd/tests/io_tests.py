import json
import os
import tempfile
import unittest

from ..io import read_whitelist
from ..io import read_vulnerabilities
from ..models import Whitelist


class ReadWhitelistTestCase(unittest.TestCase):

    def test_filename_does_not_exist(self):
        filename = 'this file does not exist.json'
        whitelist = read_whitelist(filename)
        self.assertIsNone(whitelist)

    def test_invalid_json(self):
        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write('{')
        whitelist = read_whitelist(temp_whitelist_filename.name)
        self.assertIsNone(whitelist)

    def test_happy_path_from_file(self):
        whitelist_as_json_doc = {'ignoreSevertiesAtOrBelow': 'low'}
        # line below should not throw an exception
        Whitelist(whitelist_as_json_doc)

        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write(json.dumps(whitelist_as_json_doc))
        whitelist = read_whitelist(temp_whitelist_filename.name)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist, whitelist_as_json_doc)

    def test_happy_path_from_str(self):
        whitelist_as_str = '{"ignoreSevertiesAtOrBelow": "low"}'
        # line below should not throw an exception
        Whitelist(json.loads(whitelist_as_str))

        whitelist = read_whitelist(whitelist_as_str)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist, json.loads(whitelist_as_str))


class ReadVulnerabilitiesTestCase(unittest.TestCase):

    def test_ctr(self):
        directory_name = None
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNone(vulnerabilities)

    def test_error_reading_vulnerabilities_because_of_file_with_invalid_json(self):
        directory_name = tempfile.mkdtemp()
        with open(os.path.join(directory_name, 'dave.json'), 'w+', encoding='utf-8') as fp:
            fp.write('{')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNone(vulnerabilities)

    def test_happy_path(self):
        directory_name = os.path.join(
            os.path.dirname(__file__),
            'vulnerabilities',
            'all-good')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNotNone(vulnerabilities)
        self.assertTrue(1 < len(vulnerabilities))
