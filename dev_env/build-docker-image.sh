#!/usr/bin/env bash

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <docker image name>" >&2
    exit 1
fi

DOCKER_IMAGE=${1:-}

TEMP_DOCKERFILE=$(mktemp 2> /dev/null || mktemp -t DAS)
cp "$SCRIPT_DIR_NAME/Dockerfile.template" "$TEMP_DOCKERFILE"

CONTEXT_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
pushd "${SCRIPT_DIR_NAME}/.." > /dev/null && tar zcf "$CONTEXT_DIR/package.tar.gz" . && popd > /dev/null

DEV_ENV_VERSION=$(cat "$SCRIPT_DIR_NAME/dev-env-version.txt")
if [ "${DEV_ENV_VERSION:-}" == "master" ]; then
    DEV_ENV_VERSION=latest
fi
sed \
    -i '' \
    -e "s|%DEV_ENV_VERSION%|$DEV_ENV_VERSION|g" \
    "$TEMP_DOCKERFILE"

docker build \
    -t "$DOCKER_IMAGE" \
    --file "$TEMP_DOCKERFILE" \
    "$CONTEXT_DIR"

rm -rf "$CONTEXT_DIR"

exit 0
