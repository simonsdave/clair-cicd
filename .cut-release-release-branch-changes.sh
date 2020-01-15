#!/usr/bin/env bash

# <release-branch> is assumed to be something like "release-0.9.32"

set -e

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <release-branch>" >&2
    exit 1
fi

RELEASE_BRANCH=${1:-}

REPO_ROOT_DIR=$(repo-root-dir.sh)

#
# badges
#

# requires.io
sed -i '' \
    -e \
    "s|?branch=master|?branch=${RELEASE_BRANCH}|g" \
    "${REPO_ROOT_DIR}/README.md"

# CircleCI
sed -i '' \
    -e \
    "s|/tree/master|/tree/${RELEASE_BRANCH}|g" \
    "${REPO_ROOT_DIR}/README.md"

# codecov
sed -i '' \
    -e \
    "s|/branch/master|/branch/${RELEASE_BRANCH}|g" \
    "${REPO_ROOT_DIR}/README.md"

# don't need to do anything for docker images

#
# references to files in docs and bin directories of repo
#

sed -i '' \
    -e \
    "s|(docs|(https://github.com/simonsdave/clair-cicd/blob/${RELEASE_BRANCH}/bin|g" \
    "${REPO_ROOT_DIR}/README.md"

sed -i '' \
    -e \
    "s|(bin|(https://github.com/simonsdave/clair-cicd/blob/${RELEASE_BRANCH}/bin|g" \
    "${REPO_ROOT_DIR}/README.md"

rm -f "${REPO_ROOT_DIR}/README.rst"
build-readme-dot-rst.sh

rm -rf "${REPO_ROOT_DIR}/dist"
build-python-package.sh

exit 0
