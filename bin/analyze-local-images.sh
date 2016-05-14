#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

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

docker pull simonsdave/clair-database:latest
docker run \
    --name clair-database \
    -p 5432:5432 \
    -d \
    simonsdave/clair-database:latest

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

docker pull quay.io/coreos/clair:latest
docker run \
    -d \
    --name clair \
    -p 6060-6061:6060-6061 \
    --link clair-database:postgres \
    -v /tmp:/tmp \
    -v $CLAIR_CONFIG_DIR:/config \
    quay.io/coreos/clair:latest \
    -config=/config/config.yaml

analyze-local-images $DOCKER_IMAGE

exit 0
