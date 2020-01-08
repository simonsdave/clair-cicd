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


class Whitelist(object):

    def __init__(self, ignore_severities_at_or_below):
        object.__init__(self)

        self.ignore_severities_at_or_below = ignore_severities_at_or_below

        # :TODO: add list of vulnerabilities to whitelist regardless of severity


class Vulnerability(object):

    def __init__(self, cve_id, severity):
        object.__init__(self)

        self.cve_id = cve_id
        self.severity = severity

    def __str__(self):
        return self.cve_id
