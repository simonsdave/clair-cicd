# clair-cicd

![Maintained](https://img.shields.io/maintenance/yes/2016.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
![Python 2.7](https://img.shields.io/badge/python-2.7-FFC100.svg?style=flat)
[![Requirements Status](https://requires.io/github/simonsdave/clair-cicd/requirements.svg?branch=master)](https://requires.io/github/simonsdave/clair-cicd/requirements/?branch=master)
[![Build Status](https://travis-ci.org/simonsdave/clair-cicd.svg?branch=master)](https://travis-ci.org/simonsdave/clair-cicd)
[![Coverage Status](https://coveralls.io/repos/github/simonsdave/clair-cicd/badge.svg?branch=master)](https://coveralls.io/github/simonsdave/clair-cicd?branch=master)

**THIS REPO IS A WIP (but starting to see real progress)**

[Clair](https://github.com/coreos/clair),
[released by CoreOS in Nov '16](https://coreos.com/blog/vulnerability-analysis-for-containers/),
is a very effective tool for statically analyzing docker images
and assessing images against known vulnerabilities.
Integrating Clair into a CI/CD pipeline:

1. can be complex (believe this is mostly a documentation challenge)
1. create performance problems (building the Postgres vulnerabilities database is slow)
1. once vulnerabilities are identified there's a lack of prescriptive
guidance on how to act on the vulnerabilities report in an automated manner

This repo was created to address each of the above problems.

## Background

The roots of this repo center around the belief that:

* services should be run in Docker containers and thus a CI/CD
pipeline should be focused on the automated generation, assessment
and ultimately deployment of Docker images
* understanding and assessing the risk profile of services is important
ie. security is important
* risk is assessed differently for *production* and *development* releases
* Docker images should not be pushed to a Docker registry until
their risk profile is understood
* inserted into the CI/CD pipeline, Clair can be an effective
foundation for providing an automated assessment of a Docker image's
vulnerabilities before the image is pushed to a Docker registry
* the CI/CD pipeline has to be fast. how fast? ideally < 5 minutes
between code commit and automated (CD) deployment begins rolling
out a change

## Key Concepts

* vulnerabilities
* docker image
* static vulnerability analysis
* vulnerability whitelist
* service profile

## Key Participants

* service engineer
* security analyst

## How to Use

### Getting Started

To get started with using ```clair-cicd```
to assess vulnerabilities,
a service engineer inserts a single line of code into a
service's CI script.
Part of the CI script's responsibility is to build
```username/repo:tag``` and then push ```username/repo:tag```
to a docker registry.
The single line of ```clair-cicd``` code should appear after
```username/repo:tag``` is built but
before ```username/repo:tag``` is pushed to a docker registry.
In this simple case, ```assess-image-risk.sh``` returns a zero
exit status if ```username/repo:tag``` contains no known vulnerabilities
above a medium severity. If ```username/repo:tag``` contains
any known vulnerabilities with a severity higher than medium ```assess-image-risk.sh``` returns a non-zero exit status
and the build should fail immediately
ie. the build should fail before ```username/repo:tag```
is pushed to a docker registry.

```bash
curl -s -L https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | bash -s -- "username/repo:tag"
```

### Adding a Vulnerability Whitelist

Consider this scenario:

* a high severity vulnerability exists
in a command line utility that's part of ```username/repo:tag```
* you have a 100% confidence that the utility will never be used

Following the steps described in the previous section
would result in the CI process failing because the high severity
vulnerability would be detected. But this failure seems
inappropriate given the knowledge that the command line
tool with the vulnerability would never be used.
Enter ```clair-cicd's``` whitelists.

Whitelists are json documents which allow security analysts
to influence ```clair-cicd's``` vulnerability assessment.
Whitelist expectations:

* maintained by security analyst **not** service engineer
* checked into source code control and appropriate change
management process used to make changes (code reviews, feature
branches, etc)

### Adding a Service Profile

* service engineer defines a service profile

## How it Works

Assumptions/requirements:

* bash & curl are available
* docker daemon is installed and running
* docker remote API is running on ```http://172.17.42.1:2375```
* all testing and dev has been done on Ubuntu 14.04 so no promises about other
platforms (feedback on this would be very helpful)

There are 4 moving pieces:

1. ```assess-image-risk.sh``` is bash script which does
the heavy lifting to co-ordinate
the interaction of the 3 other moving pieces
1. the [Clair](https://github.com/coreos/clair) service which
is packaged inside the docker image [quay.io/coreos/clair:latest](https://quay.io/repository/coreos/clair?tag=latest)
1. [Clair's](https://github.com/coreos/clair) vulnerability database
which is packaged inside the docker image
[simonsdave/clair-database:latest](https://hub.docker.com/r/simonsdave/clair-database/) -
a [Travis Cron Job](https://docs.travis-ci.com/user/cron-jobs/)
is used to rebuild
[simonsdave/clair-database:latest](https://hub.docker.com/r/simonsdave/clair-database/)
daily to ensure
the vulnerability database is kept current
1. a set of Python and Bash vulnerability analysis scripts packaged in the
[simonsdave/clair-cicd-tools:latest](https://hub.docker.com/r/simonsdave/clair-cicd-tools/)
docker image

## References

* [FIVE SECRETS AND TWO COMMON “GOTCHAS” OF VULNERABILITY SCANNING](https://www.kennasecurity.com/resources/secrets-gotchas-of-vuln-scanning)
