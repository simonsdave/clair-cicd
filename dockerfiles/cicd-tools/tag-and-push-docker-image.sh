#!/usr/bin/env bash

set -e

if [ $# != 4 ]; then
    echo "usage: $(basename "$0") <username> <password> <current tag> <new tag>" >&2
    exit 1
fi

USERNAME=${1:-}
PASSWORD=${2:-}
CURRENT_TAG=${3:-}
NEW_TAG=${4:-}

BASE_IMAGE=clair-cicd-tools
CURRENT_IMAGE="$USERNAME/$BASE_IMAGE:$CURRENT_TAG"
NEW_IMAGE="$USERNAME/$BASE_IMAGE:$NEW_TAG"

docker tag "$CURRENT_IMAGE" "$NEW_IMAGE"

echo "$PASSWORD" | docker login --username="$USERNAME" --password-stdin
docker push "$NEW_IMAGE"

exit 0
