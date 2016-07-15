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

    def __hash__(self):
        return self.severity

    def __lt__(self, other):
        return self.severity < other.severity

    def __le__(self, other):
        return self.severity <= other.severity

    def __eq__(self, other):
        return self.severity == other.severity

    def __nq__(self, other):
        return self.severity != other.severity


class Whitelist(object):

    def __init__(self, whitelist):
        object.__init__(self)

        self.whitelist = whitelist

    @property
    def ignore_severties_at_or_below(self):
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
        # "Severity":"Low","Metadata":{"NVD":{"CVSSv2":{"Score":1.9,"Vectors":"AV:L/AC:M/Au:N/C:N/I:N"}}}
        # use Severity if it exists otherwise uses Score where low = 0.0-3.9,
        # medium = 4.0-6.9, high = 7.0-10.0
        return Severity(self.vulnerability['Severity'])
