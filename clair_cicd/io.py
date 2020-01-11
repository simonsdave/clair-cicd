import json
import logging
import os

import jsonschema

from . import jsonschemas
from .models import Severity
from .models import Vulnerability
from .models import WhitelistVulnerability
from .models import Whitelist

_logger = logging.getLogger(__name__)

_json_scheme = 'json://'
_file_scheme = 'file://'


def _read_whitelist_from_json_doc(whitelist_as_json_doc):
    whitelist_vulnerabilities = []
    for whitelist_vulnerability_as_json_doc in whitelist_as_json_doc.get('vulnerabilities', []):
        whitelist_vulnerability = WhitelistVulnerability(
            whitelist_vulnerability_as_json_doc['cveId'],
            whitelist_vulnerability_as_json_doc['rationale'])
        whitelist_vulnerabilities.append(whitelist_vulnerability)

    whitelist = Whitelist(Severity(
        whitelist_as_json_doc['ignoreSevertiesAtOrBelow']),
        whitelist_vulnerabilities)

    return whitelist


def read_whitelist(filename_or_json):
    """Attempt to populate and return a ```Whitelist```.

    As the name implies, ```filename_or_json``` is either a filename
    or a string representing a JSON doc. More specifically,
    ```filename_or_json``` is assumed to be a JSON doc if it starts
    a { character otherwise ```filename_or_json``` is assumed to be
    the name of a file with UTF-8 character encoding.

    If any kind of error occurs ```None``` is returned.
    """
    if filename_or_json is None:
        return None

    if filename_or_json.startswith(_json_scheme):
        try:
            whitelist_as_json_doc = json.loads(filename_or_json[len(_json_scheme):])
            jsonschema.validate(whitelist_as_json_doc, jsonschemas.whitelist)
            return _read_whitelist_from_json_doc(whitelist_as_json_doc)
        except Exception:
            _logger.error("Looked like JSON but guess not :-( - %s\n", filename_or_json)
            return None

    if filename_or_json.startswith(_file_scheme):
        try:
            with open(filename_or_json[len(_file_scheme):], 'r', encoding='utf-8') as f:
                whitelist_as_json_doc = json.load(f)
                jsonschema.validate(whitelist_as_json_doc, jsonschemas.whitelist)
                return _read_whitelist_from_json_doc(whitelist_as_json_doc)
        except Exception as ex:
            _logger.error("Could not read whitelist from '%s' - %s\n", filename_or_json, ex)
            return None

    _logger.error("Could not read whitelist from '%s'\n", filename_or_json)

    return None


def read_vulnerabilities(directory_name):
    """Using the Clair API (https://coreos.com/clair/docs/latest/api_v1.html#vulnerabilities)
    one JSON file is created per layer in a docker image. The JSON file lists a set of
    features for each layer and associated with each feature are vulnerabilities.

    ```directory_name``` is the name of the directory in which to look for the JSON files.

    The function returns a list of ```models.Vulnerability``` instances.

    If ```directory_name``` is ```None``` then an emptly list is returned.

    If any kind of error occurs ```None``` is returned.
    """

    if directory_name is None:
        return []

    _logger.info("Looking for vulnerabilities in directory '%s'", directory_name)
    try:
        filenames = [filename for filename in os.listdir(directory_name) if filename.strip().lower().endswith('.json')]
    except Exception as ex:
        _logger.error("Could not read vulnerabilities from directory '%s' - %s", directory_name, ex)
        return None
    _logger.info("Found %d files with vulnerabilities in directory '%s'", len(filenames), directory_name)

    vulnerabilities_by_cve_id = {}

    for filename in filenames:
        try:
            vulnerabilities_in_layer_by_cve_id = {}

            absolute_filename = os.path.join(directory_name, filename)
            _logger.info("Looking for vulnerabilities in '%s'", absolute_filename)

            with open(absolute_filename, 'r', encoding='utf-8') as fp:
                features = json.load(fp).get('Layer', {}).get('Features', [])
                for feature in features:
                    vulnerabilities = feature.get('Vulnerabilities', [])
                    for vulnerability_as_json_doc in vulnerabilities:
                        jsonschema.validate(vulnerability_as_json_doc, jsonschemas.vulnerability)

                        vulnerability = Vulnerability(
                            vulnerability_as_json_doc['Name'],
                            Severity(vulnerability_as_json_doc['Severity']))

                        vulnerabilities_in_layer_by_cve_id[vulnerability.cve_id] = vulnerability

            _logger.info(
                "Found %d vulnerabilities in '%s'",
                len(vulnerabilities_in_layer_by_cve_id),
                absolute_filename)

            vulnerabilities_by_cve_id.update(vulnerabilities_in_layer_by_cve_id)
        except Exception:
            _logger.error("Could not read vulnerabilities from '%s'", absolute_filename)
            return None

    _logger.info(
        "Found %d vulnerabilities in %d files in directory '%s'",
        len(vulnerabilities_by_cve_id),
        len(filenames),
        directory_name)

    return vulnerabilities_by_cve_id.values()
