import json
import logging
import os

from .models import Whitelist
from .models import Vulnerability

_logger = logging.getLogger(__name__)


def read_whitelist(filename_or_json):
    """Attempt to populate and return a ```Whitelist```.

    As the name implies, ```filename_or_json``` is either a filename
    or a string representing a JSON doc. More specifically,
    ```filename_or_json``` is assumed to be a JSON doc if it starts
    a { character otherwise ```filename_or_json``` is assumed to be
    the name of a file with UTF-8 character encoding.

    If any kind of error occurs ```None``` is returned.
    """
    if 0 < len(filename_or_json) and '{' == filename_or_json[0]:
        try:
            whitelist = Whitelist(json.loads(filename_or_json))
        except Exception:
            _logger.error("Looked like JSON but guess not :-( - %s\n", filename_or_json)
            return None
    else:
        try:
            with open(filename_or_json, 'r', encoding='utf-8') as f:
                whitelist = Whitelist(json.load(f))
        except Exception as ex:
            _logger.error("Could not read whitelist from '%s' - %s\n", filename_or_json, ex)
            return None

    return whitelist


def read_vulnerabilities(directory):
    """...

    If ```directory``` is ```None``` then an empty dictionary
    is returned.

    If any kind of error occurs ```None``` is returned.
    """

    if directory is None:
        return {}

    try:
        filenames = os.listdir(directory)
    except Exception:
        _logger.error("Could not read vulnerabilities from directory '%s'", directory)
        return None

    vulnerabilities_by_cve_id = {}

    for filename in filenames:
        absolute_filename = os.path.join(directory, filename)
        try:
            with open(absolute_filename) as fp:
                features = json.load(fp).get('Layer', {}).get('Features', [])
                for feature in features:
                    vulnerabilities = feature.get('Vulnerabilities', [])
                    for vulnerability in vulnerabilities:
                        vulnerability = Vulnerability(vulnerability)
                        vulnerabilities_by_cve_id[vulnerability.cve_id] = vulnerability
        except Exception:
            _logger.error("Could not read vulnerabilities from '%s'", absolute_filename)
            return None

    return vulnerabilities_by_cve_id.values()
