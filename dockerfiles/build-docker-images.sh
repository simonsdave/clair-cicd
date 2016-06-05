#!/usr/bin/env bash
#
# This script builds all docker images
#

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

VERBOSE=0
VERBOSE_FLAG=""
TAG=""

while true
do
    OPTION=`echo ${1:-} | awk '{print tolower($0)}'`
    case "$OPTION" in
        -v)
            shift
            VERBOSE=1
            VERBOSE_FLAG=-v
            ;;
        -t)
            shift
            TAG=${1:-}
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 2 ] && [ $# != 4 ]; then
    echo "usage: `basename $0` [-v] [-t <tag>] <package-tar-gz> <username> [<email> <password>]" >&2
    exit 1
fi

PACKAGE_TAR_GZ=${1:-}
USERNAME=${2:-}
EMAIL=${3:-}
PASSWORD=${4:-}

"$SCRIPT_DIR_NAME/cicd-tools/build-docker-image.sh" \
    $VERBOSE_FLAG \
    -t "$TAG" \
    "$PACKAGE_TAR_GZ" \
    "$USERNAME" \
    "$EMAIL" \
    "$PASSWORD"
if [ $? != 0 ]; then
    exit 1
fi

"$SCRIPT_DIR_NAME/database/build-docker-image.sh" \
    $VERBOSE_FLAG \
    -t "$TAG" \
    "$USERNAME" \
    "$EMAIL" \
    "$PASSWORD"
if [ $? != 0 ]; then
    exit 1
fi

exit 0
