# clair-cicd
![Maintained](https://img.shields.io/maintenance/yes/2016.svg)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](http://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/simonsdave/clair-cicd.svg?branch=master)](https://travis-ci.org/simonsdave/clair-cicd)

**THIS REPO IS A WIP (but starting to see real progress)**

[Clair](https://github.com/coreos/clair),
[released by CoreOS in Nov '16](https://coreos.com/blog/vulnerability-analysis-for-containers/),
is a very effective tool for statically analyzing docker images
and assessing images against known vulnerabilities.
Integrating Clair into a CI/CD pipeline:

1. can be complex (think this is mostly a documentation thing)
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
