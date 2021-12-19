# clair-cicd

![Maintained](https://img.shields.io/maintenance/yes/2021.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![Python 3.7](https://img.shields.io/badge/python-3.7-blue.svg)](https://www.python.org/downloads/release/python-370/)
[![Requirements](https://requires.io/github/simonsdave/clair-cicd/requirements.svg?branch=master)](https://requires.io/github/simonsdave/clair-cicd/requirements/?branch=master)
[![CodeFactor](https://www.codefactor.io/repository/github/simonsdave/clair-cicd/badge/master)](https://www.codefactor.io/repository/github/simonsdave/clair-cicd/overview/master)
[![Language grade: Python](https://img.shields.io/lgtm/grade/python/g/simonsdave/clair-cicd.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/simonsdave/clair-cicd/context:python)
[![CircleCI](https://circleci.com/gh/simonsdave/clair-cicd/tree/master.svg?style=shield)](https://circleci.com/gh/simonsdave/clair-cicd/tree/master)
[![codecov](https://codecov.io/gh/simonsdave/clair-cicd/branch/master/graph/badge.svg)](https://codecov.io/gh/simonsdave/clair-cicd/branch/master)
[![Total alerts](https://img.shields.io/lgtm/alerts/g/simonsdave/clair-cicd.svg?logo=lgtm&logoWidth=18)](https://lgtm.com/projects/g/simonsdave/clair-cicd/alerts/)
[![docker-simonsdave/clair-cicd-clair](https://img.shields.io/badge/docker-simonsdave%2Fclair--cicd--clair-blue.svg)](https://hub.docker.com/r/simonsdave/clair-cicd-clair/)
[![docker-simonsdave/clair-cicd-database](https://img.shields.io/badge/docker-simonsdave%2Fclair--cicd--database-blue.svg)](https://hub.docker.com/r/simonsdave/clair-cicd-database/)

[Clair](https://github.com/coreos/clair),
[released by CoreOS in Nov '16](https://coreos.com/blog/vulnerability-analysis-for-containers/),
is a very effective tool for [statically analyzing](https://en.wikipedia.org/wiki/Static_program_analysis) docker images
to determine which known vulnerabilities exist in the images.
Integrating Clair into a CI/CD pipeline:

1. is complex (believe this is partly a documentation challenge)
1. creates performance problems (building the Clair required Postgres database
   of vulnerabilities is slow)
1. in and of itself is insufficient from a risk assessment point of view
   because once vulnerabilities
   are identified there's a lack of prescriptive guidance on how to act on
   the identified vulnerabilities

This repo was created to address the above challenges.

## Background

The roots of this repo center around the following beliefs:

* when inserted into a CI/CD pipeline, [Clair](https://github.com/coreos/clair)
  can be a very effective foundation for automating the risk assessment of Docker image
  vulnerabilities
* services should be run in Docker containers and thus CI/CD
  pipelines should be focused on the automated generation, assessment
  and ultimately deployment of Docker images
* understanding and assessing the risk profile of services is important
  ie. security is important
* Docker images should **not** be pushed to a Docker registry until
  their risk profile is understood (this is an important one)
* CI/CD pipelines should to be fast. how fast? ideally < 5 minutes
  between code commit and automated deployment begins
* there should be a clear division of responsibilities between
  those who create a docker image (service engineer) and those who
  determine the risk of vulnerabilities in a docker image (security analyst)
* the risk assessment process should generate evidence which
  can be used to understand the risk assessment decision

## Key Participants

* service engineer - responsible for implementing a service that is packaged
  in a docker image
* security analyst - responsible for defining whitelists which are consumed
  by ```clair_cicd``` to influence Docker image risk assessment decisions

## How to Use

### Getting Started

To start using ```clair-cicd```,
a service engineer inserts a single line of code into a service's CI pipeline.
The single line of code runs the shell script [assess-image-risk.sh](bin/assess-image-risk.sh).
Part of the CI pipeline's responsibility is to build the docker image
and then push that docker image to a docker registry.
The single line of ```clair-cicd``` code should appear after the docker image
is built and tested but before the docker image is pushed to a docker registry.

In this simple case, [assess-image-risk.sh](bin/assess-image-risk.sh) returns a zero
exit status if the docker image contains no known vulnerabilities
above a medium severity. If the docker image contains
any known vulnerabilities with a severity higher than medium, [assess-image-risk.sh](bin/assess-image-risk.sh)
returns a non-zero exit status and the build fails
ie. the build should fail before the docker image is pushed to a docker registry.

The example illustrates what's described about for the [alpine:3.4 docker image](https://hub.docker.com/_/alpine?tab=tags).

```bash
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- alpine:3.4
~> echo $?
0
~>
```

#### Understanding the Risk Assessment Decision

To understand how ```assess-image-risk.sh``` is making its risk assessment
decision try using the ```-v``` flag.

```bash
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- -v alpine:3.4
2020-01-12 16:43:35 pulling clair database image 'simonsdave/clair-cicd-database:latest'
2020-01-12 16:44:17 successfully pulled clair database image
2020-01-12 16:44:17 starting clair database container 'clair-db-c1dbb5f93ae98755'
2020-01-12 16:44:23 waiting for database server in container 'clair-db-c1dbb5f93ae98755' to start ...........................
2020-01-12 16:44:54 successfully started clair database container
2020-01-12 16:44:54 clair configuration in '/var/folders/7x/rr443kj575s8zz54jrbrp4jc0000gn/T/tmp.ElAlhGNl'
2020-01-12 16:44:59 pulling clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:45:13 successfully pulled clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:45:13 starting clair container 'clair-e9573ae537134fa0'
2020-01-12 16:45:15 successfully started clair container 'clair-e9573ae537134fa0'
2020-01-12 16:45:15 saving docker image 'alpine:3.4' to '/tmp/tmp.IaNHCH'
2020-01-12 16:45:16 successfully saved docker image 'alpine:3.4'
2020-01-12 16:45:16 starting to create clair layers
2020-01-12 16:45:16 creating clair layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:45:16 successfully created clair layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:45:16 done creating clair layers
2020-01-12 16:45:16 starting to get vulnerabilities for clair layers
2020-01-12 16:45:16 saving vulnerabilities to directory '/tmp/tmp.MDncHN'
2020-01-12 16:45:16 getting vulnerabilities for layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:45:16 successfully got vulnerabilities for layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:45:16 done getting vulnerabilities for clair layers
2020-01-12 21:45:17 INFO io:89 Looking for vulnerabilities in directory '/tmp/tmp.MDncHN'
2020-01-12 21:45:17 INFO io:95 Found 1 files with vulnerabilities in directory '/tmp/tmp.MDncHN'
2020-01-12 21:45:17 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.MDncHN/378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d.json'
2020-01-12 21:45:17 INFO io:122 Found 0 vulnerabilities in '/tmp/tmp.MDncHN/378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d.json'
2020-01-12 21:45:17 INFO io:133 Found 0 vulnerabilities in 1 files in directory '/tmp/tmp.MDncHN'
2020-01-12 21:45:17 INFO assessor:19 Assessment starts
2020-01-12 21:45:17 INFO assessor:26 Assessment ends - pass
~> echo $?
0
~>
```

#### Adding a Vulnerability Whitelist

In the above examples a default vulnerability whitelist was used.
When specified as a JSON doc, this whitelist would be:

```json
{
  "ignoreSevertiesAtOrBelow": "medium"
}
```

By default, [assess-image-risk.sh](bin/assess-image-risk.sh)
returns a non-zero exit status if any vulnerabilities are identified
in the image with a severity higher than medium. The medium is
derived from the default vulnerability whitelist.

The example below illustrate how to specify a vulnerability whitelist
and with a severity other than medium. Note the use of the ```json://```
prefix to indicate this is an inline whitelist.

```bash
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- -v --whitelist 'json://{"ignoreSevertiesAtOrBelow": "negligible"}' ubuntu:18.04
2020-01-12 16:46:56 pulling clair database image 'simonsdave/clair-cicd-database:latest'
2020-01-12 16:46:58 successfully pulled clair database image
2020-01-12 16:46:58 starting clair database container 'clair-db-3b0811925f7e8bc2'
2020-01-12 16:46:59 waiting for database server in container 'clair-db-3b0811925f7e8bc2' to start .............................
2020-01-12 16:47:32 successfully started clair database container
2020-01-12 16:47:32 clair configuration in '/var/folders/7x/rr443kj575s8zz54jrbrp4jc0000gn/T/tmp.BXCs3Giy'
2020-01-12 16:47:34 pulling clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:47:36 successfully pulled clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:47:36 starting clair container 'clair-fc579c71e7daba57'
2020-01-12 16:47:38 successfully started clair container 'clair-fc579c71e7daba57'
2020-01-12 16:47:38 saving docker image 'ubuntu:18.04' to '/tmp/tmp.lPDhNd'
2020-01-12 16:47:43 successfully saved docker image 'ubuntu:18.04'
2020-01-12 16:47:43 starting to create clair layers
2020-01-12 16:47:43 creating clair layer 'cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd'
2020-01-12 16:47:43 successfully created clair layer 'cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd'
2020-01-12 16:47:43 creating clair layer '27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54'
2020-01-12 16:47:44 successfully created clair layer '27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54'
2020-01-12 16:47:44 creating clair layer 'd80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e'
2020-01-12 16:47:44 successfully created clair layer 'd80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e'
2020-01-12 16:47:44 creating clair layer '1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d'
2020-01-12 16:47:44 successfully created clair layer '1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d'
2020-01-12 16:47:44 done creating clair layers
2020-01-12 16:47:44 starting to get vulnerabilities for clair layers
2020-01-12 16:47:44 saving vulnerabilities to directory '/tmp/tmp.dkfgmI'
2020-01-12 16:47:44 getting vulnerabilities for layer 'cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd'
2020-01-12 16:47:44 successfully got vulnerabilities for layer 'cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd'
2020-01-12 16:47:44 getting vulnerabilities for layer '27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54'
2020-01-12 16:47:44 successfully got vulnerabilities for layer '27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54'
2020-01-12 16:47:44 getting vulnerabilities for layer 'd80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e'
2020-01-12 16:47:44 successfully got vulnerabilities for layer 'd80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e'
2020-01-12 16:47:44 getting vulnerabilities for layer '1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d'
2020-01-12 16:47:44 successfully got vulnerabilities for layer '1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d'
2020-01-12 16:47:44 done getting vulnerabilities for clair layers
2020-01-12 21:47:45 INFO io:89 Looking for vulnerabilities in directory '/tmp/tmp.dkfgmI'
2020-01-12 21:47:45 INFO io:95 Found 4 files with vulnerabilities in directory '/tmp/tmp.dkfgmI'
2020-01-12 21:47:45 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.dkfgmI/27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54.json'
2020-01-12 21:47:45 INFO io:122 Found 33 vulnerabilities in '/tmp/tmp.dkfgmI/27a911bb510bf1e9458437f0f44216fd38fd08c462ed7aa026d91aab8c054e54.json'
2020-01-12 21:47:45 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.dkfgmI/cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd.json'
2020-01-12 21:47:45 INFO io:122 Found 33 vulnerabilities in '/tmp/tmp.dkfgmI/cc59b0ca1cf21d77c81a98138703008daa167b1ab1a115849d498dba64e738dd.json'
2020-01-12 21:47:45 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.dkfgmI/1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d.json'
2020-01-12 21:47:45 INFO io:122 Found 33 vulnerabilities in '/tmp/tmp.dkfgmI/1ee34a985f7aef86436a5519f5ad83f866a74c7d9a0c22e47c4213ee9cb64e6d.json'
2020-01-12 21:47:45 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.dkfgmI/d80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e.json'
2020-01-12 21:47:45 INFO io:122 Found 33 vulnerabilities in '/tmp/tmp.dkfgmI/d80735acaa72040a0a98ca3ae6891f9abb4e2f5d627b4099c4fefdc3ce1e696e.json'
2020-01-12 21:47:45 INFO io:133 Found 33 vulnerabilities in 4 files in directory '/tmp/tmp.dkfgmI'
2020-01-12 21:47:45 INFO assessor:19 Assessment starts
2020-01-12 21:47:45 INFO assessor:34 Assessing vulnerability CVE-2018-11236 - start
2020-01-12 21:47:45 INFO assessor:52 Vulnerability CVE-2018-11236 @ severity medium greater than whitelist severity @ negligible - fail
2020-01-12 21:47:45 INFO assessor:36 Assessing vulnerability CVE-2018-11236 - finish
2020-01-12 21:47:45 INFO assessor:23 Assessment ends - fail
~> echo $?
1
~>
```

The above is an example of an inline whitelist. It's also possible
to specify a whitelist in a file.
The example below illustrates the usage.
Note use of the ```file://``` prefix to indicate the whitelist is contained in a file.

```bash
~> cat whitelist.json
{
  "ignoreSevertiesAtOrBelow": "medium"
}
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- -v --whitelist file://whitelist.json alpine:3.4
2020-01-12 16:48:41 pulling clair database image 'simonsdave/clair-cicd-database:latest'
2020-01-12 16:48:42 successfully pulled clair database image
2020-01-12 16:48:42 starting clair database container 'clair-db-191152e37b864e4b'
2020-01-12 16:48:43 waiting for database server in container 'clair-db-191152e37b864e4b' to start .............................
2020-01-12 16:49:16 successfully started clair database container
2020-01-12 16:49:16 clair configuration in '/var/folders/7x/rr443kj575s8zz54jrbrp4jc0000gn/T/tmp.GdlBNmiG'
2020-01-12 16:49:19 pulling clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:49:20 successfully pulled clair image 'simonsdave/clair-cicd-clair:latest'
2020-01-12 16:49:20 starting clair container 'clair-747d1c50606fba7e'
2020-01-12 16:49:21 successfully started clair container 'clair-747d1c50606fba7e'
2020-01-12 16:49:22 saving docker image 'alpine:3.4' to '/tmp/tmp.Eldkbe'
2020-01-12 16:49:23 successfully saved docker image 'alpine:3.4'
2020-01-12 16:49:23 starting to create clair layers
2020-01-12 16:49:23 creating clair layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:49:23 successfully created clair layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:49:23 done creating clair layers
2020-01-12 16:49:23 starting to get vulnerabilities for clair layers
2020-01-12 16:49:23 saving vulnerabilities to directory '/tmp/tmp.pCOhlL'
2020-01-12 16:49:23 getting vulnerabilities for layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:49:23 successfully got vulnerabilities for layer '378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d'
2020-01-12 16:49:23 done getting vulnerabilities for clair layers
2020-01-12 21:49:23 INFO io:89 Looking for vulnerabilities in directory '/tmp/tmp.pCOhlL'
2020-01-12 21:49:23 INFO io:95 Found 1 files with vulnerabilities in directory '/tmp/tmp.pCOhlL'
2020-01-12 21:49:23 INFO io:104 Looking for vulnerabilities in '/tmp/tmp.pCOhlL/378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d.json'
2020-01-12 21:49:23 INFO io:122 Found 0 vulnerabilities in '/tmp/tmp.pCOhlL/378cb6b4a17e08c366cebd813d218f60889848387fa61a56ac054ca027a4890d.json'
2020-01-12 21:49:23 INFO io:133 Found 0 vulnerabilities in 1 files in directory '/tmp/tmp.pCOhlL'
2020-01-12 21:49:23 INFO assessor:19 Assessment starts
2020-01-12 21:49:23 INFO assessor:26 Assessment ends - pass
~> echo $?
0
~>
```

Specific vulnerabilities can also be whitelisted.
The example below illustrates this capability.
If you add the ```-v``` (verbose) flag to ```assess-image-risk.sh```
you see exactly how whitelisted vulnerabilities impact the risk assessment
with statements like ```Vulnerability CVE-2019-13627 in whitelist - pass```

```bash
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- --whitelist 'json://{"ignoreSevertiesAtOrBelow":"low"}' ubuntu:18.04
~> echo $?
1
~> cat whitelist.json
{
  "ignoreSevertiesAtOrBelow": "low",
  "vulnerabilities": [
    { "cveId": "CVE-2018-20839", "rationale": "reason #1" },
    { "cveId": "CVE-2019-5188", "rationale": "reason #2" },
    { "cveId": "CVE-2018-11236", "rationale": "reason #3" },
    { "cveId": "CVE-2019-13627", "rationale": "reason #4" },
    { "cveId": "CVE-2019-13050", "rationale": "reason #5" },
    { "cveId": "CVE-2018-11237", "rationale": "reason #6" },
    { "cveId": "CVE-2018-19591", "rationale": "reason #7" }
  ]
}
~> curl -s -L \
  https://raw.githubusercontent.com/simonsdave/clair-cicd/master/bin/assess-image-risk.sh | \
  bash -s -- --whitelist 'file://whitelist.json' ubuntu:18.04
~> echo $?
0
~>
```

ITO whitelists it's worth seeing issue #7 which says:

> When specifying the whitelist for ```assess-image-risk.sh``` with the ```--whitelist``` command line argument, should support ```https://``` scheme in addition to the existing ```json://```, ```file://``` schemes. Why is this important? Ideally whitelists should be maintained by a security analyst not a service engineer. This means that whitelists should be maintained in another repo with appropriate change management process. The ```json://``` and ```file://``` schemes are fine for maintaining whitelists in the same repo is service code. However, it would be better to maintain whitelists in a repo that is readonly for service engineers and editable only by security analysts who could apply appropriate change management processes are used to make changes (code reviews, feature  branches, etc).

## How it Works + Requirements/Assumptions

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

From the samples at the start of this doc you'll see the approach of
curl'ing the latest release of [assess-image-risk.sh](bin/assess-image-risk.sh)
into a localy run bash shell. [assess-image-risk.sh](bin/assess-image-risk.sh)
then spins up a container using the [simonsdave/clair-database](https://hub.docker.com/r/simonsdave/clair-database/). Another container is then run
using [simonsdave/clair-cicd-clair](https://hub.docker.com/r/simonsdave/clair-cicd-clair/)
with the [simonsdave/clair-cicd-clair](https://hub.docker.com/r/simonsdave/clair-cicd-clair/) container
being able to talk with the [simonsdave/clair-database](https://hub.docker.com/r/simonsdave/clair-database/) container. Once the [simonsdave/clair-cicd-clair](https://hub.docker.com/r/simonsdave/clair-cicd-clair/) container is running, [assess-image-risk.sh](bin/assess-image-risk.sh) docker exec's [this bash script](dockerfiles/clair/assess-image-risk.sh)
which does the actual risk assessment.

Armed with the understanding of how ```clair-cicd``` works you'll
appreciate that the ability to execute [assess-image-risk.sh](bin/assess-image-risk.sh)
is what defines the requirements for the execution
environment. [assess-image-risk.sh](bin/assess-image-risk.sh) is a bash script used to launch
the risk assessment process and as such it's this script which defines the bulk of
the assumptions/requirements for ```clair-cicd``` - the script uses docker, sed and openssl
so all these need to be available in the environment running ```clair-cicd```

## References

* [1 Nov '20 - A Practical Introduction to Container Security](https://cloudberry.engineering/article/practical-introduction-container-security/)
* [5 Aug '20 - How to do vulnerability management with Docker and CI/CD](https://circleci.com/blog/how-to-do-vulnerability-management-with-docker-and-ci-cd/)
* [20 May '20 - Security scanners for Python and Docker: from code to dependencies](https://pythonspeed.com/articles/docker-python-security-scan/)
* [29 Jan '20 - What Is DevSecOps, and How Is It Different from DevOps?](https://research.g2.com/insights/what-is-devsecops-and-how-is-it-different-from-devops)
* [26 Dec '19 - CoreOS Clair — Part 2: Installation & Integration](https://medium.com/paloit/coreos-clair-part-2-installation-integration-558ec664cece)
* [4 Oct '19 - CoreOS Clair — Part 1: Container Image Scanning](https://medium.com/paloit/container-image-scanning-with-coreos-clair-part-1-17152d6a8421)
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
