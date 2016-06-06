#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""This script analyzes Clair generated vulnerabilities.
The script is intended to be incorporated into a CI process
to generate a non-zero exit status when vulnerabilities
exceed an acceptable threshold.
"""

import json
import optparse
import sys

from clair_cicd import io


class CommandLineParser(optparse.OptionParser):

    def __init__(self):

        optparse.OptionParser.__init__(
            self,
            'usage: %prog [options] <docker image>',
            description='cli to analyze results of Clair identified vulnerabilities')

        help = 'verbose - default = false'
        self.add_option(
            '--verbose',
            '-v',
            action='store_true',
            dest='verbose',
            help=help)

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

    def parse_args(self, *args, **kwargs):
        (clo, cla) = optparse.OptionParser.parse_args(self, *args, **kwargs)
        if len(cla) != 1:
            self.error('no docker image')

        return (clo, cla)


if __name__ == '__main__':

    clp = CommandLineParser()
    (clo, cla) = clp.parse_args()

    whitelist = io.read_whitelist(clo.whitelist)
    vulnerabilities = io.read_vulnerabilities(cla[0])

    if clo.verbose:
        indent = '-' * 50

        for vulnerability in vulnerabilities:
            print indent
            print json.dumps(vulnerability.vulnerability, indent=2)

        print indent

    sys.exit(0)
