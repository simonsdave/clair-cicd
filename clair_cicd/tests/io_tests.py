import json
import os
import tempfile
import unittest
import uuid

from ..io import read_whitelist
from ..io import read_vulnerabilities
from ..models import Severity


class ReadWhitelistTestCase(unittest.TestCase):

    def test_filename_is_none(self):
        whitelist = read_whitelist(None)
        self.assertIsNone(whitelist)

    def test_unknonn_schema(self):
        whitelist = read_whitelist('unknonwn://this')
        self.assertIsNone(whitelist)

    def test_filename_does_not_exist(self):
        whitelist = read_whitelist('file://this file does not exist.json')
        self.assertIsNone(whitelist)

    def test_invalid_json_in_file(self):
        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write('{')
        whitelist = read_whitelist('file://%s' % temp_whitelist_filename.name)
        self.assertIsNone(whitelist)

    def test_invalid_json_in_str(self):
        whitelist_as_str = '{'
        whitelist = read_whitelist('json://%s' % whitelist_as_str)
        self.assertIsNone(whitelist)

    def test_happy_path_from_file_no_vulnerabilities(self):
        ignore_severities_at_or_below = Severity('low')
        whitelist_as_json_doc = {'ignoreSevertiesAtOrBelow': str(ignore_severities_at_or_below)}

        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write(json.dumps(whitelist_as_json_doc))
        whitelist = read_whitelist('file://%s' % temp_whitelist_filename.name)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist.ignore_severities_at_or_below, ignore_severities_at_or_below)

    def test_happy_path_from_file_with_zero_vulnerabilities(self):
        ignore_severities_at_or_below = Severity('low')
        whitelist_as_json_doc = {
            'ignoreSevertiesAtOrBelow': str(ignore_severities_at_or_below),
            'vulnerabilities': [
            ],
        }

        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write(json.dumps(whitelist_as_json_doc))
        whitelist = read_whitelist('file://%s' % temp_whitelist_filename.name)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist.ignore_severities_at_or_below, ignore_severities_at_or_below)

    def test_happy_path_from_file_with_vulnerabilities(self):
        ignore_severities_at_or_below = Severity('low')
        whitelist_as_json_doc = {
            'ignoreSevertiesAtOrBelow': str(ignore_severities_at_or_below),
            'vulnerabilities': [
                {
                    'cveId': uuid.uuid4().hex,
                    'rationale': uuid.uuid4().hex,
                },
                {
                    'cveId': uuid.uuid4().hex,
                    'rationale': uuid.uuid4().hex,
                },
                {
                    'cveId': uuid.uuid4().hex,
                    'rationale': uuid.uuid4().hex,
                },
            ],
        }

        temp_whitelist_filename = tempfile.NamedTemporaryFile()
        with open(temp_whitelist_filename.name, 'w+', encoding='utf-8') as fp:
            fp.write(json.dumps(whitelist_as_json_doc))
        whitelist = read_whitelist('file://%s' % temp_whitelist_filename.name)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist.ignore_severities_at_or_below, ignore_severities_at_or_below)
        self.assertEqual(len(whitelist.vulnerabilities), len(whitelist_as_json_doc['vulnerabilities']))
        for (wlv, jdv) in zip(whitelist.vulnerabilities, whitelist_as_json_doc['vulnerabilities']):
            self.assertEqual(wlv.cve_id, jdv['cveId'])
            self.assertEqual(wlv.rationale, jdv['rationale'])

    def test_happy_path_from_str_no_vulnerabilities(self):
        ignore_severities_at_or_below = Severity('low')
        whitelist_as_str = '{"ignoreSevertiesAtOrBelow": "%s"}' % ignore_severities_at_or_below

        whitelist = read_whitelist('json://%s' % whitelist_as_str)

        self.assertIsNotNone(whitelist)
        self.assertEqual(whitelist.ignore_severities_at_or_below, ignore_severities_at_or_below)


class ReadVulnerabilitiesTestCase(unittest.TestCase):

    def test_ctr(self):
        vulnerabilities = read_vulnerabilities(None)
        self.assertEqual([], vulnerabilities)

    def test_directory_does_not_exist(self):
        directory_name = os.path.join(
            os.path.dirname(__file__),
            'vulnerabilities',
            'directory-that-does-not-exist')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNone(vulnerabilities)

    def test_error_reading_vulnerabilities_because_of_file_with_invalid_json(self):
        directory_name = tempfile.mkdtemp()
        with open(os.path.join(directory_name, 'dave.json'), 'w+', encoding='utf-8') as fp:
            fp.write('{')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNone(vulnerabilities)

    def test_unknown_severity(self):
        directory_name = os.path.join(
            os.path.dirname(__file__),
            'vulnerabilities',
            'unknown-severity')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNotNone(vulnerabilities)

    def test_happy_path(self):
        directory_name = os.path.join(
            os.path.dirname(__file__),
            'vulnerabilities',
            'all-good')
        vulnerabilities = read_vulnerabilities(directory_name)
        self.assertIsNotNone(vulnerabilities)
        self.assertTrue(1 < len(vulnerabilities))
