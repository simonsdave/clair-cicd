#!/usr/bin/env bash

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <docker image name>" >&2
    exit 1
fi

DOCKER_IMAGE=${1:-}

CONTEXT_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
pushd "$(repo-root-dir.sh)" > /dev/null && tar zcf "${CONTEXT_DIR}/package.tar.gz" . && popd > /dev/null

docker build \
    -t "${DOCKER_IMAGE}" \
    --file "${SCRIPT_DIR_NAME}/Dockerfile" \
    --build-arg "CIRCLE_CI_EXECUTOR=$(get-circle-ci-executor.sh)" \
    "${CONTEXT_DIR}"

rm -rf "${CONTEXT_DIR}"

exit 0
