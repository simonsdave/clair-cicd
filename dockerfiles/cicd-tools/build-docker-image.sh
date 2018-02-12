#!/usr/bin/env bash
#
# This script builds the clair-cicd-tools docker image
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

if [ ! -r "$PACKAGE_TAR_GZ" ]; then
    echo "can't find package @ '$PACKAGE_TAR_GZ'" >&2
    exit 1
fi

IMAGENAME=$USERNAME/clair-cicd-tools:$TAG

cp "$PACKAGE_TAR_GZ" "$SCRIPT_DIR_NAME/package.tar.gz"
docker build -t "$IMAGENAME" "$SCRIPT_DIR_NAME"
rm "$SCRIPT_DIR_NAME/package.tar.gz"

exit 0
