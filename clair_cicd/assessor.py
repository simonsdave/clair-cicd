class VulnerabilitiesRiskAssessor(object):

    def __init__(self, verbose, whitelist, vulnerabilities):
        object.__init__(self)

        self.verbose = verbose
        self.whitelist = whitelist
        self.vulnerabilities = vulnerabilities

    def assess(self):
        """Returns ```True``` if the risk is deemed acceptable
        otherwise returns ```False```."""
        for vulnerability in self.vulnerabilities:
            if self.whitelist.ignore_severties_at_or_below < vulnerability.severity:
                # :TODO: add code to check whitelist for vulnerability
                return False

        return True
