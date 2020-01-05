import jsonschema

from . import jsonschemas


class Severity(object):

    # these labels need to be in order of increasing severity
    _severity_as_strs = [
        'negligible',
        'low',
        'medium',
        'high',
    ]

    def __init__(self, severity_as_str):
        object.__init__(self)

        self.severity = type(self)._severity_as_strs.index(severity_as_str.strip().lower())

    def __str__(self):
        return type(self)._severity_as_strs[self.severity]

    def __hash__(self):
        return hash(self.severity)

    def __lt__(self, other):
        return self.severity < other.severity

    def __le__(self, other):
        return self.severity <= other.severity

    def __eq__(self, other):
        return self.severity == other.severity

    def __ne__(self, other):
        return self.severity != other.severity


class Whitelist(dict):

    def __init__(self, *args, **kwargs):
        dict.__init__(self, *args, **kwargs)

        jsonschema.validate(self, jsonschemas.whitelist)

    @property
    def ignore_severties_at_or_below(self):
        return Severity(self['ignoreSevertiesAtOrBelow'])

    # :TODO: add list of vulnerabilities to whitelist regardless of severity


class Vulnerability(dict):

    def __init__(self, *args, **kwargs):
        """'''vulnerability''' is expected to be a dictionary
        of the form illustrated by the example below. Name and
        Severity are the only two required proprities.

            {
              "Name": "CVE-2016-1238",
              "NamespaceName": "ubuntu:14.04",
              "Description": "something that could be long ...",
              "Link": "http://people.ubuntu.com/~ubuntu-security/cve/CVE-2016-1238",
              "Severity": "Medium",
              "Metadata": {
                "NVD": {
                  "CVSSv2": {
                    "Score": 7.2,
                    "Vectors": "AV:L/AC:L/Au:N/C:C/I:C"
                  }
                }
              }
            }
        """
        dict.__init__(self, *args, **kwargs)

        jsonschema.validate(self, jsonschemas.vulnerability)

    def __str__(self):
        return self.cve_id

    @property
    def cve_id(self):
        return self['Name']

    @property
    def severity(self):
        # :TODO: use Severity if it exists otherwise uses Score
        # where low = 0.0-3.9, medium = 4.0-6.9 & high = 7.0-10.0
        return Severity(self['Severity'])
