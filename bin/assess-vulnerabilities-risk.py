#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""This script analyzes Clair generated vulnerabilities.
The script is intended to be incorporated into a CI process
to generate a non-zero exit status when vulnerabilities
exceed an acceptable threshold.
"""

import json
import logging
import optparse
import re
import sys
import time

import clair_cicd
from clair_cicd import io
from clair_cicd.assessor import VulnerabilitiesRiskAssessor


_logger = logging.getLogger(__name__)


def _check_logging_level(option, opt, value):
    """Type checking function for command line parser's 'logginglevel' type."""
    reg_ex_pattern = "^(DEBUG|INFO|WARNING|ERROR|CRITICAL|FATAL)$"
    reg_ex = re.compile(reg_ex_pattern, re.IGNORECASE)
    if reg_ex.match(value):
        return getattr(logging, value.upper())
    fmt = (
        "option %s: should be one of "
        "DEBUG, INFO, WARNING, ERROR, CRITICAL or FATAL"
    )
    raise optparse.OptionValueError(fmt % opt)


class CommandLineOption(optparse.Option):
    """Adds new option types to the command line parser's base option types."""
    new_types = (
        'logginglevel',
    )
    TYPES = optparse.Option.TYPES + new_types
    TYPE_CHECKER = optparse.Option.TYPE_CHECKER.copy()
    TYPE_CHECKER['logginglevel'] = _check_logging_level


class CommandLineParser(optparse.OptionParser):

    def __init__(self):

        optparse.OptionParser.__init__(
            self,
            'usage: %prog [options] <vulnerabilities directory>',
            description='cli to analyze results of Clair identified vulnerabilities',
            version='%%prog %s' % clair_cicd.__version__,
            option_class=CommandLineOption)

        default = None
        help = 'whitelist - default = %s' % default
        self.add_option(
            '--whitelist',
            '--wl',
            action='store',
            dest='whitelist',
            default=default,
            type='string',
            help=help)

        default = logging.ERROR
        fmt = (
            "logging level [DEBUG,INFO,WARNING,ERROR,CRITICAL,FATAL] - "
            "default = %s"
        )
        help = fmt % logging.getLevelName(default)
        self.add_option(
            "--log",
            action="store",
            dest="logging_level",
            default=default,
            type="logginglevel",
            help=help)

    def parse_args(self, *args, **kwargs):
        (clo, cla) = optparse.OptionParser.parse_args(self, *args, **kwargs)
        if len(cla) != 1:
            sys.stderr.write(self.get_usage())
            sys.exit(1)

        return (clo, cla)


if __name__ == '__main__':

    #
    # parse command line
    #
    clp = CommandLineParser()
    (clo, cla) = clp.parse_args()

    #
    # configure logging ... remember gmt = utc
    #
    logging.Formatter.converter = time.gmtime
    logging.basicConfig(
        level=clo.logging_level,
        datefmt='%Y-%m-%dT%H:%M:%S',
        format='%(asctime)s.%(msecs)03d+00:00 %(process)d '
        '%(levelname)5s %(module)s:%(lineno)d %(message)s')

    #
    # read all the various bits we need into memory
    #
    whitelist = io.read_whitelist(clo.whitelist)
    if whitelist is None:
        sys.exit(1)

    vulnerabilities_directory = cla[0]
    vulnerabilities = io.read_vulnerabilities(vulnerabilities_directory)
    if vulnerabilities is None:
        sys.exit(2)

    #
    # can be helpful for debugging
    #
    for vulnerability in vulnerabilities:
        _logger.debug('-' * 50)
        _logger.debug(json.dumps(vulnerability.vulnerability, indent=2))
    _logger.debug('-' * 50)

    #
    # this is what it's all been leading up to:-)
    #
    vra = VulnerabilitiesRiskAssessor(whitelist, vulnerabilities)
    sys.exit(0 if vra.assess() else 1)
