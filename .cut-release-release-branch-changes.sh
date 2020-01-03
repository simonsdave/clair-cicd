#!/usr/bin/env bash

# :TODO: more work is require here ...

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <release-branch>" >&2
    exit 1
fi

RELEASE_BRANCH=${1:-}

sed -i '' \
    -e \
    "s|/tree/master|/tree/${RELEASE_BRANCH}|g" \
    "${SCRIPT_DIR_NAME}/README.md"

rm -f "${SCRIPT_DIR_NAME}/README.rst"
build-readme-dot-rst.sh

rm -rf "${SCRIPT_DIR_NAME}/dist"
build-python-package.sh

exit 0
