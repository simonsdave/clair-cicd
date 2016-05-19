#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

echo_if_verbose() {
    if [ 1 -eq ${VERBOSE:-0} ]; then
        echo "$(date "+%Y-%m-%d %k:%M:%S") ${1:-}"
    fi
    return 0
}

#
# parse command line arguments
#

VERBOSE=0

while true
do
    OPTION=`echo ${1:-} | awk '{print tolower($0)}'`
    case "$OPTION" in
        -v)
            shift
            VERBOSE=1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 1 ]; then
    echo "usage: `basename $0` [-v] <docker image id>" >&2
    exit 1
fi

DOCKER_IMAGE=${1:-}

CLAIR_DATABASE_IMAGE=simonsdave/clair-database:latest

echo_if_verbose "pulling clair database image '$CLAIR_DATABASE_IMAGE'"
docker pull $CLAIR_DATABASE_IMAGE > /dev/null
if [ $? != 0 ]; then
    echo "error pulling clair database image '$CLAIR_DATABASE_IMAGE'" >&2
    exit 1
fi
echo_if_verbose "successfully pulled clair database image"

CLAIR_DATABASE_CONTAINER=clair-db-$(openssl rand -hex 8)
echo_if_verbose "starting clair database container '$CLAIR_DATABASE_CONTAINER'"
docker run --name $CLAIR_DATABASE_CONTAINER -d $CLAIR_DATABASE_IMAGE > /dev/null
if [ $? != 0 ]; then
    echo "error starting clair database container '$CLAIR_DATABASE_CONTAINER'" >&2
    exit 1
fi
echo_if_verbose "successfully started clair database container"

CLAIR_CONFIG_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
CLAIR_CONFIG_YAML=$CLAIR_CONFIG_DIR/config.yaml

curl \
    -s \
    -o "$CLAIR_CONFIG_YAML" \
    -L \
    https://raw.githubusercontent.com/coreos/clair/master/config.example.yaml

sed \
    -i \
    -e 's|source:|source: postgresql://postgres@clair-database:5432/clair?sslmode=disable|g' \
    "$CLAIR_CONFIG_YAML"

CLAIR_IMAGE=quay.io/coreos/clair:latest
docker pull $CLAIR_IMAGE > /dev/null

CLAIR_CONTAINER=clair-$(openssl rand -hex 8)
docker run \
    -d \
    --name $CLAIR_CONTAINER \
    -p 6060:6060 \
    --link $CLAIR_DATABASE_CONTAINER:clair-database \
    -v /tmp:/tmp \
    -v $CLAIR_CONFIG_DIR:/config \
    $CLAIR_IMAGE \
    -config=/config/config.yaml \
    > /dev/null
if [ $? != 0 ]; then
    echo "error starting clair container '$CLAIR_CONTAINER'" >&2
    exit 1
fi

#
# if it's not already around, grab the script to does the actual analysis
#
if [ ! -x analyze-local-images ]; then
    go get -u github.com/coreos/clair/contrib/analyze-local-images
fi

#
# setup done! time to run the analysis
#
# analyze-local-images -endpoint "http://127.0.0.1:6060" $DOCKER_IMAGE
analyze-local-images $DOCKER_IMAGE

#
# cleanup ...
#
docker kill $CLAIR_CONTAINER > /dev/null
docker rm $CLAIR_CONTAINER > /dev/null

docker kill $CLAIR_DATABASE_CONTAINER > /dev/null
docker rm $CLAIR_DATABASE_CONTAINER > /dev/null

exit 0
