#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""This script summarizes the output of Clair's analyze-local-images
utility. The script is intended to be incorporated into a CI process
to generate a non-zero exit status when the vulnerability report
exceeds the accepted threshold.

docker \
    run \
    --rm \
    --link clair-52d5afeb97ad0757:clair \
    -v /tmp:/tmp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    simonsdave/clair-cicd-tools \
    assess-image-risk.py --drapi http://172.17.42.1:2375 --clair http://clair:6060 simonsdave/ecs-services:latest
"""

import json
import optparse
import os
import sys


class Vulnerability(object):

    vulnerabilities_by_cve_id = {}

    vulnerabilities_by_severity = {}

    def __init__(self, vulnerability):
        object.__init__(self)

        self.vulnerability = vulnerability

        cls = type(self)

        if self.cve_id not in cls.vulnerabilities_by_cve_id:
            cls.vulnerabilities_by_cve_id[self.cve_id] = self

            if self.severity not in cls.vulnerabilities_by_severity:
                cls.vulnerabilities_by_severity[self.severity] = []
            cls.vulnerabilities_by_severity[self.severity].append(self)

    def __str__(self):
        return self.cve_id

    @property
    def cve_id(self):
        return self.vulnerability['Name']

    @property
    def severity(self):
        return self.vulnerability['Severity']


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
            action='store_false',
            dest='verbose',
            help=help)

    def parse_args(self, *args, **kwargs):
        (clo, cla) = optparse.OptionParser.parse_args(self, *args, **kwargs)
        if len(cla) != 1:
            self.error('no docker image')

        return (clo, cla)


class Layer(object):

    def __init__(self, filename):
        object.__init__(self)

        self.filename = filename

        self._vulnerabilities_loaded = False

    def __str__(self):
        return self.id

    def load_vulnerabilities(self):
        assert not self._vulnerabilities_loaded
        self._vulnerabilities_loaded = True

        with open(self.filename) as fp:
            features = json.load(fp).get('Layer', {}).get('Features', [])
            for feature in features:
                vulnerabilities = feature.get('Vulnerabilities', [])
                for vulnerability in vulnerabilities:
                    Vulnerability(vulnerability)


class Layers(list):

    def __init__(self, directory):
        list.__init__(self)

        for filename in os.listdir(directory):
            self.append(Layer(os.path.join(directory, filename)))


if __name__ == '__main__':

    clp = CommandLineParser()
    (clo, cla) = clp.parse_args()

    for layer in Layers(cla[0]):
        layer.load_vulnerabilities()

    for severity in Vulnerability.vulnerabilities_by_severity.keys():
        print '%s - %d' % (
            severity,
            len(Vulnerability.vulnerabilities_by_severity[severity]),
        )

    for vulnerability in Vulnerability.vulnerabilities_by_cve_id.values():
        print '-' * 50
        print vulnerability.cve_id
        print json.dumps(vulnerability.vulnerability, indent=2)

    sys.exit(0)
