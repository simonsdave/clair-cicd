FROM quay.io/coreos/clair:v2.1.2

MAINTAINER Dave Simons

RUN apk add --no-cache curl jq bash python3 tzdata \
    && cp /usr/share/zoneinfo/Canada/Eastern /etc/localtime

# :TODO: tie this version to the version in CircleCI
# per https://circleci.com/docs/2.0/building-docker-images/#docker-version

# per https://github.com/Cethy/alpine-docker-client/blob/master/Dockerfile
# useful https://download.docker.com/linux/static/stable/x86_64/
RUN mkdir -p /tmp/download \
    && curl -s -L https://download.docker.com/linux/static/stable/x86_64/docker-19.03.5.tgz | tar -xz -C /tmp/download \
    && mv /tmp/download/docker/docker /usr/local/bin/ \
    && rm -rf /tmp/download

COPY assess-image-risk.sh /usr/local/bin/assess-image-risk.sh

COPY package.tar.gz /tmp/package.tar.gz
RUN python3.7 -m pip install /tmp/package.tar.gz
RUN rm /tmp/package.tar.gz
