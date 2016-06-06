class Severity(object):

    severity_as_strs = [
        'negligible',
        'low',
        'medium',
        'high',
    ]

    def __init__(self, severity_as_str):
        object.__init__(self)

        self.severity = type(self).severity_as_strs.index(severity_as_str.strip().lower())

    def __hash__(self):
        return self.severity

    def __lt__(self, other):
        return self.severity < other.severity

    def __le__(self, other):
        return self.severity <= other.severity


class Whitelist(object):

    def __init__(self, whitelist):
        object.__init__(self)

        self.whitelist = whitelist

    @property
    def ignoreSevertiesAtOrBelow(self):
        return Severity(self.whitelist.get('ignoreSevertiesAtOrBelow', 'Medium'))


class Vulnerability(object):

    def __init__(self, vulnerability):
        object.__init__(self)

        self.vulnerability = vulnerability

    def __str__(self):
        return self.cve_id

    @property
    def cve_id(self):
        return self.vulnerability['Name']

    @property
    def severity(self):
        return Severity(self.vulnerability['Severity'])
