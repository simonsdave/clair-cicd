#!/usr/bin/env bash

#
# Assuming <existing-image-name> is of the format <hub-user>/<repo-name>:<old-tag>,
# tag <existing-image-name> as <hub-user>/<repo-name>:<tag>, login to dockerhub using
# <hub-user> plus <password> and then push <hub-user>/<repo-name>:<tag> to dockerhub.
#

set -e

if [ $# != 3 ]; then
    echo "usage: $(basename "$0") <existing-image-name> <tag> <password>" >&2
    exit 1
fi

EXISTING_IMAGE_NAME=${1:-}
TAG=${2:-}
PASSWORD=${3:-}

NEW_IMAGE_NAME="${EXISTING_IMAGE_NAME%:*}:${TAG}"

docker tag "${EXISTING_IMAGE_NAME}" "${NEW_IMAGE_NAME}"

echo "${PASSWORD}" | docker login --username="${NEW_IMAGE_NAME%/*}" --password-stdin
docker push "${NEW_IMAGE_NAME}"

exit 0
