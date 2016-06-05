#!/usr/bin/env bash
#
# This script builds the clair-cicd-tools docker image
#

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

VERBOSE=0
TAG=""

while true
do
    OPTION=`echo ${1:-} | awk '{print tolower($0)}'`
    case "$OPTION" in
        -v)
            shift
            VERBOSE=1
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

if [ ! -r "$PACKAGE_TAR_GZ" ]; then
    echo "can't find package @ '$PACKAGE_TAR_GZ'" >&2
    exit 1
fi

IMAGENAME=$USERNAME/clair-cicd-tools
if [ "$TAG" != "" ]; then
    IMAGENAME=$IMAGENAME:$TAG
fi

cp "$PACKAGE_TAR_GZ" "$SCRIPT_DIR_NAME/package.tar.gz"
docker build -t $IMAGENAME "$SCRIPT_DIR_NAME"
rm "$SCRIPT_DIR_NAME/package.tar.gz"

if [ "$EMAIL" != "" ]; then
    docker login --email="$EMAIL" --username="$USERNAME" --password="$PASSWORD"
    docker push $IMAGENAME
fi

exit 0
