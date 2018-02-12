#!/usr/bin/env bash
#
# This script builds all docker images
#

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 3 ]; then
    echo "usage: $(basename "$0") <username> <tag> <package-tar-gz>" >&2
    exit 1
fi

USERNAME=${1:-}
TAG=${2:-}
PACKAGE_TAR_GZ=${3:-}

"$SCRIPT_DIR_NAME/cicd-tools/build-docker-image.sh" \
    "$USERNAME" \
    "$TAG" \
    "$PACKAGE_TAR_GZ"

"$SCRIPT_DIR_NAME/database/build-docker-image.sh" \
    "$USERNAME" \
    "$TAG"

exit 0
