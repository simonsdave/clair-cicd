import logging


_logger = logging.getLogger(__name__)


class VulnerabilitiesRiskAssessor(object):

    def __init__(self, whitelist, vulnerabilities):
        object.__init__(self)

        self.whitelist = whitelist
        self.vulnerabilities = vulnerabilities

    def assess(self):
        """Returns ```True``` if the risk is deemed acceptable
        otherwise returns ```False```.
        """
        _logger.info('Assessment starts')

        for vulnerability in self.vulnerabilities:
            if not self._assess_vulnerability(vulnerability):
                _logger.info('Assessment ends - fail')
                return False

        _logger.info('Assessment ends - pass')

        return True

    def _assess_vulnerability(self, vulnerability):
        """Returns ```True``` if the risk is deemed acceptable for ```vulnerability```
        otherwise returns ```False```.
        """
        _logger.info('Assessing vulnerability %s - start', vulnerability)
        rv = self.__assess_vulnerability(vulnerability)
        _logger.info('Assessing vulnerability %s - finish', vulnerability)
        return rv

    def __assess_vulnerability(self, vulnerability):
        """Returns ```True``` if the risk is deemed acceptable for ```vulnerability```
        otherwise returns ```False```.
        """
        if vulnerability.cve_id in self.whitelist.vulnerabilities_by_cve_id:
            _logger.info('Vulnerability %s in whitelist - pass', vulnerability)
            return True

        if self.whitelist.ignore_severities_at_or_below < vulnerability.severity:
            _logger.info(
                'Vulnerability %s @ severity %s greater than whitelist severity @ %s - fail',
                vulnerability,
                vulnerability.severity,
                self.whitelist.ignore_severities_at_or_below)
            return False
        else:
            _logger.info(
                'Vulnerability %s @ severity %s less than or equal to whitelist severity @ %s - pass',
                vulnerability,
                vulnerability.severity,
                self.whitelist.ignore_severities_at_or_below)
            return True
