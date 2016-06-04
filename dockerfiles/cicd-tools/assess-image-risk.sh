#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

echo_if_verbose() {
    if [ 1 -eq ${VERBOSE:-0} ]; then
        echo "$(date "+%Y-%m-%d %k:%M:%S") ${1:-}"
    fi
    return 0
}

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

CLAIR_ENDPOINT=http://clair:6060
DOCKER_REMOTE_API_ENDPOINT=http://172.17.42.1:2375

echo_if_verbose "saving docker image '$DOCKER_IMAGE'"
DOCKER_IMAGE_EXPLODED_TAR_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
pushd "$DOCKER_IMAGE_EXPLODED_TAR_DIR" > /dev/null
docker save $DOCKER_IMAGE | tar xv > /dev/null
popd > /dev/null
echo_if_verbose "successfully saved docker image '$DOCKER_IMAGE'"

PREVIOUS_LAYER=""
for LAYER in $(docker history -q --no-trunc $DOCKER_IMAGE | tac)
do
    echo_if_verbose "creating clair layer '$LAYER'"

    BODY=$(mktemp 2> /dev/null || mktemp -t DAS)

    if [ "$PREVIOUS_LAYER" == "" ]; then
        echo "{\"Layer\": {\"Name\": \"$LAYER\", \"Path\": \"$DOCKER_IMAGE_EXPLODED_TAR_DIR/$LAYER/layer.tar\", \"Format\": \"Docker\"}}" > "$BODY"
    else
        echo "{\"Layer\": {\"Name\": \"$LAYER\", \"Path\": \"$DOCKER_IMAGE_EXPLODED_TAR_DIR/$LAYER/layer.tar\", \"ParentName\": \"$PREVIOUS_LAYER\", \"Format\": \"Docker\"}}" > "$BODY"
    fi

    HTTP_STATUS_CODE=$(curl \
        -s \
        -o /dev/null \
        -X POST \
        -H 'Content-Type: application/json' \
        -w '%{http_code}' \
        --data-binary @"$BODY" \
        $CLAIR_ENDPOINT/v1/layers)
    if [ $? != 0 ] || [ "$HTTP_STATUS_CODE" != "201" ]; then
        echo "error creating clair layer '$LAYER'" >&2
        exit 1
    fi

    PREVIOUS_LAYER=$LAYER

    echo_if_verbose "successfully created clair layer '$LAYER'"
done

VULNERABILTIES_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)

for LAYER in $(docker history -q --no-trunc $DOCKER_IMAGE | tac)
do
    HTTP_STATUS_CODE=$(curl \
        -s \
        -o "$VULNERABILTIES_DIR/$LAYER" \
        -w '%{http_code}' \
        "$CLAIR_ENDPOINT/v1/layers/$LAYER?vulnerabilities")
    if [ $? != 0 ] || [ "$HTTP_STATUS_CODE" != "200" ]; then
        echo "error getting vulnerabilities for layer '$LAYER'" >&2
        exit 1
    fi
done

"$SCRIPT_DIR_NAME/assess-image-risk.py" "$VULNERABILTIES_DIR"
exit $?
