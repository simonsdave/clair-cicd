#!/usr/bin/env bash
#
# This script builds all docker images
#

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

TAG=latest

while true
do
    case "${1,,}" in
        -t)
            shift
            # this script can be called by travis which may pass
            # a zero length tag argument and hence the need for
            # the if statement below
            TAG=${1:-latest}

            # this shift assumes the arg after the -t is always a
            # tag name even if it might be a zero length tag name
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
    -t "$TAG" \
    "$PACKAGE_TAR_GZ" \
    "$DOCKERHUB_USERNAME" \
    "$DOCKERHUB_PASSWORD"

"$SCRIPT_DIR_NAME/database/build-docker-image.sh" \
    -t "$TAG" \
    "$DOCKERHUB_USERNAME" \
    "$DOCKERHUB_PASSWORD"

exit 0
