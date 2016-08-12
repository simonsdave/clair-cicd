import json
import logging
import os
import sys

from models import Whitelist
from models import Vulnerability

_logger = logging.getLogger(__name__)


def read_whitelist(filename):
    """Attempt to populate and return a ```Whitelist```
    from the file pointed to by ```filename```.

    If ```filename``` is ```None``` then an empty ```Whitelist```
    is returned.

    If any kind of error occurs ```None``` is returned.
    """

    if filename is None:
        return Whitelist({})

    try:
        with open(filename) as fp:
            try:
                whitelist = Whitelist(json.load(fp))
            except Exception as ex:
                _logger.error("Could not read whitelist from '%s' - %s\n", filename, ex)
                return None
    except Exception as ex:
        _logger.error("Could not read whitelist from '%s' - %s\n", filename, ex)
        return None

    # :TODO: validate whitelist with jsonschema or done in Whitelist class

    return whitelist


def read_vulnerabilities(directory):

    vulnerabilities_by_cve_id = {}

    try:
        filenames = os.listdir(directory)
    except Exception:
        _logger.error("Could not read vulnerabilities from directory '%s'", directory)
        return None

    for filename in filenames:
        absolute_filename = os.path.join(directory, filename)
        try:
            with open(absolute_filename) as fp:
                features = json.load(fp).get('Layer', {}).get('Features', [])
                for feature in features:
                    vulnerabilities = feature.get('Vulnerabilities', [])
                    for vulnerability in vulnerabilities:
                        vulnerability = Vulnerability(vulnerability)
                        if vulnerability.cve_id not in vulnerabilities_by_cve_id:
                            vulnerabilities_by_cve_id[vulnerability.cve_id] = vulnerability
        except Exception:
            _logger.error("Could not read vulnerabilities from '%s'", absolute_filename)
            return None

    return vulnerabilities_by_cve_id.values()
