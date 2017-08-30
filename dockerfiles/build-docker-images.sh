#!/usr/bin/env bash
#
# This script builds all docker images
#

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

TAG_FLAG=""

while true
do
    case "${1,,}" in
        -t)
            shift
            # this script can be called by travis which may pass
            # a zero length tag argument and hence the need for
            # the if statement below
            if [ "${1:-}" != "" ]; then
                TAG_FLAG="-t ${1:-}"
            fi
            # the shift assumes the arg after the -t is always a
            # tag name it just might be a zero length tag name
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 2 ] && [ $# != 3 ]; then
    echo "usage: $(basename "$0") [-t <tag>] <package-tar-gz> <username> [<password>]" >&2
    exit 1
fi

PACKAGE_TAR_GZ=${1:-}
DOCKERHUB_USERNAME=${2:-}
DOCKERHUB_PASSWORD=${3:-}

"$SCRIPT_DIR_NAME/cicd-tools/build-docker-image.sh" \
    "$TAG_FLAG" \
    "$PACKAGE_TAR_GZ" \
    "$DOCKERHUB_USERNAME" \
    "$DOCKERHUB_PASSWORD"
if [ $? != 0 ]; then
    exit 1
fi

"$SCRIPT_DIR_NAME/database/build-docker-image.sh" \
    "$TAG_FLAG" \
    "$DOCKERHUB_USERNAME" \
    "$DOCKERHUB_PASSWORD"
if [ $? != 0 ]; then
    exit 1
fi

exit 0
