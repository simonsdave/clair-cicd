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
VERBOSE_FLAG=""

while true
do
    OPTION=`echo ${1:-} | awk '{print tolower($0)}'`
    case "$OPTION" in
        -v)
            shift
            VERBOSE=1
            VERBOSE_FLAG=-v
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

DOCKER_IMAGE_TO_ANALYZE=${1:-}

CLAIR_DATABASE_IMAGE=simonsdave/clair-database:latest
CLAIR_IMAGE=quay.io/coreos/clair:latest
CLAIR_CICD_TOOLS_IMAGE=simonsdave/clair-cicd-tools:latest

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

echo_if_verbose "pulling clair image '$CLAIR_IMAGE'"
docker pull $CLAIR_IMAGE > /dev/null
if [ $? != 0 ]; then
    echo "error pulling clair image '$CLAIR_IMAGE'" >&2
    exit 1
fi
echo_if_verbose "successfully pulled clair image"

CLAIR_CONTAINER=clair-$(openssl rand -hex 8)
echo_if_verbose "starting clair container '$CLAIR_CONTAINER'"
docker run \
    -d \
    --name $CLAIR_CONTAINER \
    --expose 6060 \
    --link $CLAIR_DATABASE_CONTAINER:clair-database \
    -v /tmp:/tmp \
    -v $CLAIR_CONFIG_DIR:/config \
    $CLAIR_IMAGE \
    -log-level=debug -config=/config/config.yaml \
    > /dev/null
if [ $? != 0 ]; then
    echo "error starting clair container '$CLAIR_CONTAINER'" >&2
    exit 1
fi
echo_if_verbose "successfully started clair container '$CLAIR_CONTAINER'"

echo_if_verbose "pulling clair ci/cd tools image '$CLAIR_CICD_TOOLS_IMAGE'"
docker pull $CLAIR_CICD_TOOLS_IMAGE > /dev/null
if [ $? != 0 ]; then
    echo "error pulling clair image '$CLAIR_CICD_TOOLS_IMAGE'" >&2
    exit 1
fi
echo_if_verbose "successfully pulled clair ci/cd tools image"

docker \
    run \
    --rm \
    --link $CLAIR_CONTAINER:clair \
    -v /tmp:/tmp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    $CLAIR_CICD_TOOLS_IMAGE \
    assess-image-risk.sh $VERBOSE_FLAG $DOCKER_IMAGE_TO_ANALYZE

#
# cleanup ...
#
docker kill $CLAIR_CONTAINER > /dev/null
docker rm $CLAIR_CONTAINER > /dev/null

docker kill $CLAIR_DATABASE_CONTAINER > /dev/null
docker rm $CLAIR_DATABASE_CONTAINER > /dev/null

exit 0
