# clair-cicd

![Maintained](https://img.shields.io/maintenance/yes/2020.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
![PythonVersions](https://img.shields.io/pypi/pyversions/clair-cicd.svg?style=flat)
![status](https://img.shields.io/pypi/status/clair-cicd.svg?style=flat)
[![PyPI](https://img.shields.io/pypi/v/clair-cicd.svg?style=flat)](https://pypi.python.org/pypi/clair-cicd)
[![Requirements](https://requires.io/github/simonsdave/clair-cicd/requirements.svg?branch=master)](https://requires.io/github/simonsdave/clair-cicd/requirements/?branch=master)
[![CircleCI](https://circleci.com/gh/simonsdave/clair-cicd.svg?style=shield)](https://circleci.com/gh/simonsdave/clair-cicd)
[![codecov](https://codecov.io/gh/simonsdave/clair-cicd/branch/master/graph/badge.svg)](https://codecov.io/gh/simonsdave/clair-cicd)
[![docker-simonsdave/clair-cicd-database](https://img.shields.io/badge/docker-simonsdave%2Fclair%20cicd%20database-blue.svg)](https://hub.docker.com/r/simonsdave/clair-cicd-database/)
[![docker-simonsdave/clair-cicd-clair](https://img.shields.io/badge/docker-simonsdave%2Fclair%20cicd%20clair-blue.svg)](https://hub.docker.com/r/simonsdave/clair-cicd-clair/)

```
Repo Status = this repo is a WIP but starting to show some promise!
```

[Clair](https://github.com/coreos/clair),
[released by CoreOS in Nov '16](https://coreos.com/blog/vulnerability-analysis-for-containers/),
is a very effective tool for statically analyzing docker images
and assessing images against known vulnerabilities.
Integrating Clair into a CI/CD pipeline:

1. is complex (believe this is partly a documentation challenge)
1. creates performance problems (building the Postgres vulnerabilities database is slow)
1. in and of itself is insufficient from a risk assessment point of view because once vulnerabilities
are identified there's a lack of prescriptive guidance on how to act on
the identified vulnerabilities

This repo was created to address the above challenges.

## Background

The roots of this repo center around the belief that:

* [Clair](https://github.com/coreos/clair) can be a very effective
foundation for the automated assessment of Docker image
vulnerabilities when inserted into the CI/CD pipeline
* services should be run in Docker containers and thus a CI/CD
pipeline should be focused on the automated generation, assessment
and ultimately deployment of Docker images
* understanding and assessing the risk profile of services is important
ie. security is important
* risk is assessed differently for docker images that could find their
way to *production* vs docker images that will only ever be used in *development*
* Docker images should **not** be pushed to a Docker registry until
their risk profile is understood (this is an important one)
* the CI/CD pipeline has to be fast. how fast? ideally < 5 minutes
between code commit and automated (CD) deployment begins rolling
out a change
* there should be a clear division of responsibilities between
those who create a docker image (service engineer) and those who
determine the risk of vulnerabilities in a docker image (security analyst)
* the risk assessment process must generate evidence which
can be used to understand the risk assessment decision

## Key Concepts

* docker image
* vulnerabilities
* static vulnerability analysis
* vulnerability whitelist

## Key Participants

* service engineer - responsible for implementing a service that is packaged
in a docker image
* security analyst - responsible for defining whitelists

## How to Use

### Getting Started

To start using ```clair-cicd```
a service engineer inserts a single line of code into a service's CI pipeline.
The single line of code runs the shell script [assess-image-risk.sh](bin/assess-image-risk.sh).
Part of the CI pipeline's responsibility is to build the docker image ```username/repo:tag```
and then push ```username/repo:tag``` to a docker registry.
The single line of ```clair-cicd``` code should appear after ```username/repo:tag```
is built and tested but before ```username/repo:tag``` is pushed to a docker registry.

In this simple case, [assess-image-risk.sh](bin/assess-image-risk.sh) returns a zero
exit status if ```username/repo:tag``` contains no known vulnerabilities
above a medium severity. If ```username/repo:tag``` contains
any known vulnerabilities with a severity higher than medium [assess-image-risk.sh](bin/assess-image-risk.sh)
returns a non-zero exit status and the build fails
ie. the build should fail before ```username/repo:tag``` is pushed to a docker registry.

```bash
curl -s -L https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | bash -s -- "username/repo:tag"
```

### Medium -> High

* :TODO:

### Adding a Vulnerability Whitelist

Consider this scenario:

* a high severity vulnerability exists
in a command line utility that's part of ```username/repo:tag```
* you have a 100% confidence that the utility will never be used

Following the steps described in the previous section
would result in the CI process failing because the high severity
vulnerability would be detected and ```assess-image-risk.sh```
would return a non-zero exit status. But this failure seems
inappropriate given the knowledge that the command line
tool with the vulnerability would never be used.
Enter ```clair-cicd's``` whitelists.

Whitelists are json documents which allow security analysts
to influence ```assess-image-risk.sh``` risk assessment.
Whitelist expectations:

* maintained by security analyst **not** service engineer
* checked into source code control and appropriate change
management processes are used to make changes (code reviews, feature
branches, etc)

## How it Works

Assumptions/requirements:

* [assess-image-risk.sh](bin/assess-image-risk.sh) is a bash script used to launch
the risk assessment process and as such it's this script which defines the bulk of
the assumptions/requirements for ```clair-cicd``` - the script uses docker, sed and openssl
so all these need to be available in the environment running ```clair-cicd```
* :TODO: which docker versions are supported?

There are 3 moving pieces:

1. [assess-image-risk.sh](bin/assess-image-risk.sh) is bash script which does
the heavy lifting to co-ordinate
the interaction of the 2 other moving pieces
1. [Clair's](https://github.com/coreos/clair) vulnerability database
which is packaged inside the docker image
[simonsdave/clair-database](https://hub.docker.com/r/simonsdave/clair-database/) -
a [CircleCI](https://circleci.com/) cron job
is used to rebuild
[simonsdave/clair-database](https://hub.docker.com/r/simonsdave/clair-database/)
3 days per week to ensure
the vulnerability database is current
1. a set of Python and Bash risk assessment scripts packaged in the
[simonsdave/clair-cicd-clair](https://hub.docker.com/r/simonsdave/clair-cicd-clair/)
docker image which is based on the docker image [quay.io/coreos/clair](https://quay.io/repository/coreos/clair)
which packages up [Clair](https://github.com/coreos/clair)

## References

* [1 Oct '18 - Baking Compliance in your CI/CD Pipeline](https://thenewstack.io/baking-compliance-in-your-ci-cd-pipeline)
* [11 Sep '18 - What is DevSecOps?](https://medium.com/@aditi.chaudhry92/what-is-devsecops-cb14cfd457b2)
* [20 Jun '18 - Where in the DevOps cycle do you do security?](https://opensource.com/article/18/6/where-cycle-security-devops)
* [8 May '18 - DevSecOps: 7 habits of strong security organizations](https://enterprisersproject.com/article/2018/5/devsecops-7-habits-strong-security-organizations)
* [18 Apr '18 - The Cloudcast #343 - Container Vulnerability Scanning](http://www.thecloudcast.net/2018/04/the-cloudcast-343-container.html)
* [21 Feb '18 - Automated Compliance Testing Tool Accelerates DevSecOps](https://www.securityweek.com/automated-compliance-testing-tool-accelerates-devsecops)
* [20 Feb '18 - 6 Requirements for Achieving DevSecOps](https://securityboulevard.com/2018/02/6-requirements-for-achieving-devsecops/)
* [22 Jan '18 - DevOps and Security: How to Overcome Cultural Challenges and Transform to True DevSecOps](https://thenewstack.io/devops-security-overcome-cultural-challenges-transform-true-devsecops/)
* [15 Jan '18 - Why DevSecOps matters to IT leaders](https://enterprisersproject.com/article/2018/1/why-devsecops-matters-it-leaders)
* [27 Nov '17 - What is vulnerability management? Processes and software for prioritizing threats](https://www.csoonline.com/article/3238080/vulnerabilities/what-is-vulnerability-management-processes-and-software-for-prioritizing-threats.html)
* [23 Oct '17 - The Ten Cybersecurity Commandments](http://www.securityweek.com/ten-cybersecurity-commandments)
* [9 Oct '17 - 10 layers of Linux container security](https://opensource.com/article/17/10/10-layers-container-security)
* [5 Oct '17 - How to Maintain Security when Rolling out DevOps](https://www.informationweek.com/devops/how-to-maintain-security-when-rolling-out-devops/a/d-id/1330047?imm_mid=0f71d7&cmp=em-webops-na-na-newsltr_security_20171010_length_control)
* [26 Jan '17 - DevOps and Separation of Duties](https://www.newcontext.com/devops-and-separation-of-duties/)
* [26 Jul '16 - Injecting security into Continuous Delivery](https://www.oreilly.com/learning/injecting-security-into-continuous-delivery)
* [5 Jun '16 - <— Shifting Security to the Left](http://www.devsecops.org/blog/2016/5/20/-security)
* [Five Secrets and Two Common “Gotchas” of Vulnerability Scanning](https://www.kennasecurity.com/resources/secrets-gotchas-of-vuln-scanning)

## :TODO:

* assessor should use whitelist vulnerabilities
* vulnerabilities should be jsonschema verified
* whitelist needs to be passed from ```assess-image-risk.sh``` all the way through to ```assess-vulnerabilities-risk.py```
* unit test coverage should be 100% given how simple this code is
* ```assess-vulnerabilities-risk.py``` should support ```file:``` and ```https``` schemes for ```--whitelist``` command line arg and just pass json doc
* publish ```clair-cicd``` to PyPI
