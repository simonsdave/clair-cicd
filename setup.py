#
# to build the distrubution @ dist/clair-cicd-*.*.*.tar.gz
#
#   >git clone https://github.com/simonsdave/clair-cicd.git
#   >cd clair-cicd
#   >python setup.py sdist --formats=gztar
#

import re

from setuptools import setup

#
# this approach used below to determine ```version``` was inspired by
# https://github.com/kennethreitz/requests/blob/master/setup.py#L31
#
# why this complexity? wanted version number to be available in the
# a runtime.
#
# the code below assumes the distribution is being built with the
# current directory being the directory in which setup.py is stored
# which should be totally fine 99.9% of the time. not going to add
# the coode complexity to deal with other scenarios
#
reg_ex_pattern = r"__version__\s*=\s*['\"](?P<version>[^'\"]*)['\"]"
reg_ex = re.compile(reg_ex_pattern)
version = ""
with open('clair-cicd/__init__.py', 'r') as fd:
    for line in fd:
        match = reg_ex.match(line)
        if match:
            version = match.group('version')
            break
if not version:
    raise Exception("Can't locate project's version number")

setup(
    name='clair-cicd',
    packages=[
        'clair-cicd',
    ],
    scripts=[
        'bin/assess-image-risk.sh',
    ],
    install_requires=[
    ],
    dependency_links=[
    ],
    include_package_data=True,
    version=version,
    description='Clair CI/CD',
    author='Dave Simons',
    author_email='simonsdave@gmail.com',
    url='https://github.com/simonsdave/clair-cicd',
)
