#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 2 ]; then
    echo "usage: $(basename "$0") <package> <image-name>" >&2
    exit 1
fi

PACKAGE=${1:-}
IMAGE_NAME=${2:-}

CLAIR_VERSION=$(grep '^__clair_version__' "$(repo-root-dir.sh)/clair_cicd/__init__.py" | sed -e "s|^[^']*'||g" | sed -e 's|[^0-9]*$||g')

CONTEXT_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
cp "${SCRIPT_DIR_NAME}/assess-image-risk.sh" "${CONTEXT_DIR}/."
cp "${PACKAGE}" "${CONTEXT_DIR}/package.tar.gz"

docker build \
    -t "${IMAGE_NAME}" \
    --file "${SCRIPT_DIR_NAME}/Dockerfile" \
    --build-arg "CLAIR_VERSION=${CLAIR_VERSION}" \
    "${CONTEXT_DIR}"

rm -rf "${CONTEXT_DIR}"

exit 0
