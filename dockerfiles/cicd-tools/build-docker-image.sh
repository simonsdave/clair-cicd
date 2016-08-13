#!/usr/bin/env bash
#
# This script builds the clair-cicd-tools docker image
#

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

VERBOSE=0
TAG="latest"

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
            TAG=$1
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 2 ] && [ $# != 3 ]; then
    echo "usage: `basename $0` [-v] [-t <tag>] <package-tar-gz> <username> [<password>]" >&2
    exit 1
fi

PACKAGE_TAR_GZ=${1:-}
DOCKERHUB_USERNAME=${2:-}
DOCKERHUB_PASSWORD=${3:-}

if [ ! -r "$PACKAGE_TAR_GZ" ]; then
    echo "can't find package @ '$PACKAGE_TAR_GZ'" >&2
    exit 1
fi

IMAGENAME=$DOCKERHUB_USERNAME/clair-cicd-tools:$TAG

cp "$PACKAGE_TAR_GZ" "$SCRIPT_DIR_NAME/package.tar.gz"
docker build -t $IMAGENAME "$SCRIPT_DIR_NAME"
rm "$SCRIPT_DIR_NAME/package.tar.gz"

if [ "$DOCKERHUB_PASSWORD" != "" ]; then
    echo "logging in to dockerhub"
    docker login --username="$DOCKERHUB_USERNAME" --password="$DOCKERHUB_PASSWORD"
    echo "logged in to dockerhub"

    docker push $IMAGENAME
fi

exit 0
