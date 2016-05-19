#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""This script summarizes the output of Clair's analyze-local-images
utility. The script is intended to be incorporated into a CI process
to generate a non-zero exit status when the vulnerability report
exceeds the accepted threshold.
"""

import re
import os
import sys


class Vulnerability(object):

    vulnerabilities = []

    vulnerabilities_by_severity = {}

    def __init__(self, id, severity):
        object.__init__(self)

        self.id = id
        self.severity = severity

        cls = type(self)

        cls.vulnerabilities.append(self)

        if self.severity not in cls.vulnerabilities_by_severity:
            cls.vulnerabilities_by_severity[self.severity] = []
        cls.vulnerabilities_by_severity[self.severity].append(self)


if __name__ == '__main__':

    if len(sys.argv) != 1:
        fmt = 'usage: %s\n'
        msg = fmt % os.path.split(sys.argv[0])[1]
        sys.stderr.write(msg)
        sys.exit(1)

    # CVE-2015-7977 (Medium)
    reg_ex_pattern = r'^\s*(?P<id>CVE\-\d+\-\d+)\s+\((?P<severity>[^\)]+)\)\s*$'
    reg_ex = re.compile(reg_ex_pattern)

    for line in sys.stdin:
        match = reg_ex.match(line)
        if match:
            id = match.group('id')
            severity = match.group('severity')
            Vulnerability(id, severity)

    for (severity, vulnerabilities) in Vulnerability.vulnerabilities_by_severity.iteritems():
        print "%3d %s" % (len(vulnerabilities), severity)

    sys.exit(0)
