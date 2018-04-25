# to build the image
#
#   docker build -t simonsdave/clair-cicd-tools .
#
# to run the image
#
#   docker \
#       run \
#       -v $PWD/vulnerabilities:/vulnerabilities \
#       simonsdave/clair-cicd-tools \
#       assess-vulnerabilities.py -v /vulnerabilities
#
# for testing/debugging
#
#   docker run -i -t simonsdave/clair-cicd-tools /bin/bash
#
# to push to dockerhub
#
#   docker push simonsdave/clair-cicd-tools
#
FROM ubuntu:16.04

MAINTAINER Dave Simons

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y

# basic stuff to get python going
RUN apt-get install -y python
RUN apt-get install -y python-pip

COPY package.tar.gz /tmp/package.tar.gz

RUN pip install /tmp/package.tar.gz

RUN rm /tmp/package.tar.gz

ENV DEBIAN_FRONTEND newt
