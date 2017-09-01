#!/usr/bin/env bash
#
# A simple script to kill and remove all docker containers.
#

set -e

for CONTAINER_ID in $(docker ps -q); do
    docker kill "$CONTAINER_ID"
done

for CONTAINER_ID in $(docker ps -a -q); do
    docker rm "$CONTAINER_ID"
done

exit 0
