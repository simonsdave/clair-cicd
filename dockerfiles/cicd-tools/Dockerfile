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

# assess-image-risk.sh needs the docker client
RUN apt-get install -y docker.io

# assess-image-risk.sh needs curl
RUN apt-get install -y curl

# basic stuff to get python going
RUN apt-get install -y python
RUN apt-get install -y python-dev
RUN apt-get install -y python-pip
RUN pip install pip==1.5.6

ADD assess-image-risk.sh /usr/local/bin/assess-image-risk.sh
ADD assess-image-risk.py /usr/local/bin/assess-image-risk.py 
