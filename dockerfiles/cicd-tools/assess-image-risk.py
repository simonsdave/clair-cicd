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
    -v $PWD:/dave \
    simonsdave/clair-cicd-tools \
    assess-image-risk.py http://172.17.42.1:2375 http://clair:6060 simonsdave/ecs-services:latest
"""

import httplib
import json
import re
import os
import sys
import urllib

import requests


def _usage():
    """Write a high level usage message to stderr."""
    fmt = 'usage: %s <docker endpoint> <clair endpoint> <image>\n'
    msg = fmt % os.path.split(sys.argv[0])[1]
    sys.stderr.write(msg)


class Vulnerability(object):

    vulnerabilities = []

    vulnerabilities_by_cve_id = {}

    vulnerabilities_by_severity = {}

    def __init__(self, cve_id, severity):
        object.__init__(self)

        cls = type(self)

        if cve_id in cls.vulnerabilities_by_cve_id:
            return

        self.cve_id = cve_id
        self.severity = severity

        cls.vulnerabilities.append(self)

        cls.vulnerabilities_by_cve_id[self.cve_id] = self

        if self.severity not in cls.vulnerabilities_by_severity:
            cls.vulnerabilities_by_severity[self.severity] = []
        cls.vulnerabilities_by_severity[self.severity].append(self)

    def __str__(self):
        return self.cve_id


if __name__ == '__main__':

    if len(sys.argv) != 4:
        _usage()
        sys.exit(1)

    docker_remote_api_endpoint = sys.argv[1]
    clair_endpoint = sys.argv[2]
    docker_image = sys.argv[3]

    url = '%s/images/%s/history' % (
        docker_remote_api_endpoint,
        urllib.quote_plus(docker_image),
    )
    response = requests.get(url)
    if response.status_code != httplib.OK:
        msg = "Couldn't get image history for '%s' (%s)\n" % (
            docker_image,
            response.status_code,
        )
        sys.stderr.write(msg)
        sys.exit(1)

    layers = [layer['Id'] for layer in response.json()]

    for layer in layers:
        url = '%s/v1/layers/%s?vulnerabilities' % (
            clair_endpoint,
            layer,
        )
        response = requests.get(url)
        if response.status_code != httplib.OK:
            msg = "Couldn't get vulnerabilities for layer '%s' (%s)\n" % (
                layer,
                response.status_code,
            )
            sys.stderr.write(msg)
            sys.exit(1)

        features = response.json().get('Layer', {}).get('Features', [])
        for feature in features:
            vulnerabilities = feature.get('Vulnerabilities', [])
            for vulnerability in vulnerabilities:
                print vulnerability
                Vulnerability(vulnerability['Name'], vulnerability['Severity'])

    for severity in Vulnerability.vulnerabilities_by_severity.keys():
        print '%s - %d' % (severity, len(Vulnerability.vulnerabilities_by_severity[severity]))

    sys.exit(0)
