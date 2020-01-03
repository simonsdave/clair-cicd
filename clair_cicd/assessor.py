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
        for vulnerability in self.vulnerabilities:
            _logger.info('Assessing vulnerability %s - start', vulnerability)

            # :TODO: add code to check whitelist for vulnerability - ignore
            # all other checks if vulnerability is in that list

            if self.whitelist.ignore_severties_at_or_below < vulnerability.severity:
                _logger.info(
                    'Vulnerability %s @ severity %s greater than whitelist severity @ %s - fail',
                    vulnerability,
                    vulnerability.severity,
                    self.whitelist.ignore_severties_at_or_below)

                return False

            _logger.info(
                'Vulnerability %s @ severity %s less than or equal to whitelist severity @ %s - pass',
                vulnerability,
                vulnerability.severity,
                self.whitelist.ignore_severties_at_or_below)

            _logger.info('Assessing vulnerability %s - finish', vulnerability)

        return True
