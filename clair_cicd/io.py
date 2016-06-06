import json
import os
import sys

from models import Whitelist
from models import Vulnerability

def read_whitelist(filename):

    if not filename:
        return Whitelist({})

    try:
        with open(self.filename) as fp:
            whitelist = Whitelist(json.load(fp))
    except Exception:
        msg = "Could not read whitelist from '%s'\n" % self.filename
        sys.stderr.write(msg)
        sys.exit(1)

    # :TODO: validate whitelist with jsonschema

    return whitelist


def read_vulnerabilities(directory):

    vulnerabilities_by_cve_id = {}

    try:
        filenames = os.listdir(directory)
    except Exception:
        msg = "Could not read vulnerabilities from directory '%s'\n" % directory
        sys.stderr.write(msg)
        sys.exit(1)

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
            msg = "Could not read vulnerabilities from '%s'\n" % absolute_filename
            sys.stderr.write(msg)
            sys.exit(1)

    return vulnerabilities_by_cve_id.values()
