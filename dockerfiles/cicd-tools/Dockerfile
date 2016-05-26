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

RUN apt-get install -y docker.io

# git req'd by go otherwise 'go get' fails
RUN apt-get install -y git
RUN apt-get install -y golang-go
RUN mkdir /.gopath
ENV GOPATH /.gopath
ENV PATH=$PATH:/.gopath/bin

RUN go get -u github.com/coreos/clair/contrib/analyze-local-images

ADD analyze-local-images.sh /usr/local/bin/analyze-local-images.sh
ADD summarize-analyze-local-images-results.py /usr/local/bin/summarize-analyze-local-images-results.py
