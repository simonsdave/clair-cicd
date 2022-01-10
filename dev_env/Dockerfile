ARG CIRCLE_CI_EXECUTOR

FROM $CIRCLE_CI_EXECUTOR

LABEL maintainer="Dave Simons"

ENV DEBIAN_FRONTEND noninteractive

RUN mkdir /tmp/package
ADD package.tar.gz /tmp/package/.
RUN cd /tmp/package && python3.9 -m pip install --requirement requirements.txt
RUN rm -rf /tmp/package

ENV DEBIAN_FRONTEND newt
