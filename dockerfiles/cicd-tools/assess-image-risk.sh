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

DOCKER_IMAGE_EXPLODED_TAR_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
pushd "$DOCKER_IMAGE_EXPLODED_TAR_DIR" > /dev/null
docker save $DOCKER_IMAGE | tar xv
popd > /dev/null

PREVIOUS_LAYER=""
for LAYER in $(docker history -q --no-trunc $DOCKER_IMAGE | tac)
do
    BODY=$(mktemp 2> /dev/null || mktemp -t DAS)

    if [ "$PREVIOUS_LAYER" == "" ]; then
        BODY_TEMPLATE=$SCRIPT_DIR_NAME/clair-layers-template-with-parent.json
    else
        BODY_TEMPLATE=$SCRIPT_DIR_NAME/clair-layers-template-with-parent.json
    fi

    SED_SCRIPT=$(mktemp 2> /dev/null || mktemp -t DAS)
    echo "s|%NAME%|$LAYER|g" >> "$SED_SCRIPT"
    echo "s|%PATH%|$DOCKER_IMAGE_EXPLODED_TAR_DIR/$LAYER/layer.tar|g" >> "$SED_SCRIPT"
    echo "s|%PARENTNAME%|$PREVIOUS_LAYER|g" >> "$SED_SCRIPT"
    cat "$BODY_TEMPLATE" | sed -f "$SED_SCRIPT" > "$BODY"
    rm "$SED_SCRIPT"

    curl \
        -s \
        -X POST \
        -H 'Content-Type: application/json' \
        --data-binary @"$BODY" \
        http://clair:6060/v1/layers

    PREVIOUS_LAYER=$LAYER

    rm "$BODY"
done

for LAYER in $(docker history -q --no-trunc $DOCKER_IMAGE)
do
    curl -s http://clair:6060/v1/layers/$LAYER?vulnerabilities
done

exit 0
