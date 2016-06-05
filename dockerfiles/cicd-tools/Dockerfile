# to build the image
#
#   docker build -t simonsdave/clair-cicd-tools .
#
# to run the image
#
#   docker run -v /tmp:/tmp simonsdave/clair-cicd-tools analyze-local-images -v
#
# for testing/debugging
#
#   docker run -i -t simonsdave/clair-cicd-tools /bin/bash
#
# to push to dockerhub
#
#   docker push simonsdave/clair-cicd-tools
#
FROM ubuntu:14.04

MAINTAINER Dave Simons

RUN apt-get update -y

# assess-image-risk.sh needs curl
RUN apt-get install -y curl

# basic stuff to get python going
RUN apt-get install -y python
RUN apt-get install -y python-pip
RUN pip install pip==1.5.6

ADD assess-vulnerabilities.py /usr/local/bin/assess-vulnerabilities.py
