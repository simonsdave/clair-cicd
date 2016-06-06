class Whitelist(object):

    def __init__(self, whitelist):
        object.__init__(self)

        self.whitelist = whitelist

    @property
    def ignoreSevertiesAtOrBelow(self):
        return self.whitelist('ignoreSevertiesAtOrBelow', 'Medium')


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
        return self.vulnerability['Severity']
