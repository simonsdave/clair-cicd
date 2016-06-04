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

    HTTP_STATUS_CODE=$(curl \
        -s \
        -o /dev/null \
        -X POST \
        -H 'Content-Type: application/json' \
        -w '%{http_code}' \
        --data-binary @"$BODY" \
        http://clair:6060/v1/layers)
    if [ $? != 0 ] || [ "$HTTP_STATUS_CODE" != "201" ]; then
        echo "error creating clair layer '$LAYER'" >&2
        exit 1
    fi

    PREVIOUS_LAYER=$LAYER

    rm "$BODY"

    echo_if_verbose "successfully created clair layer '$LAYER'"
done

"$SCRIPT_DIR_NAME/assess-image-risk.py" --drapi "http://172.17.42.1:2375" --clair "http://clair:6060" "$DOCKER_IMAGE"
exit $?
