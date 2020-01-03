#!/usr/bin/env bash

ts() {
    # date "+%Y-%m-%d %k:%M:%S"
    date "+%Y-%m-%d %H:%M:%S"
}

echo_if_verbose() {
    if [ "1" -eq "${VERBOSE:-0}" ]; then
        echo "$@" 
    fi
    return 0
}

#
# parse command line arguments
#
VERBOSE=0
LOG_LEVEL=""
CLAIR_API_PORT=6060

while true
do
    case "$(echo "${1:-}" | tr "[:upper:]" "[:lower:]")" in
        -v)
            shift
            VERBOSE=1
            LOG_LEVEL=--log=info
            ;;
        -vv)
            shift
            VERBOSE=1
            LOG_LEVEL=--log=debug
            ;;
        --api-port)
            shift
            CLAIR_API_PORT=${1:-}
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") [-v|-vv] [--api-port <port>] <docker image>" >&2
    exit 1
fi

DOCKER_IMAGE_TO_ANALYZE=${1:-}

#
# save the docker image to be analyzed to a tar archive
# and determine which layers are in the image
#
DOCKER_IMAGE_EXPLODED_TAR_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
echo_if_verbose "$(ts) saving docker image '${DOCKER_IMAGE_TO_ANALYZE}' to '${DOCKER_IMAGE_EXPLODED_TAR_DIR}'"
pushd "${DOCKER_IMAGE_EXPLODED_TAR_DIR}" > /dev/null || echo "only here to avoid shellcheck's SC2164"
docker save "${DOCKER_IMAGE_TO_ANALYZE}" | tar xv > /dev/null
popd > /dev/null || echo "only here to avoid shellcheck's SC2164"
LAYERS=$(jq ".[0].Layers[]" < "${DOCKER_IMAGE_EXPLODED_TAR_DIR}/manifest.json" | sed -e 's|"||g' | sed -e 's|/layer.tar$||g')
echo_if_verbose "$(ts) successfully saved docker image '${DOCKER_IMAGE_TO_ANALYZE}'"

#
# Iterate through each layer in the saved image and use 
# Clair's RESTful API (https://coreos.com/clair/docs/latest/api_v1.html#layers)
# to analyze each layer.
#
echo_if_verbose "$(ts) starting to create clair layers"

PREVIOUS_LAYER=""
for LAYER in $LAYERS
do
    echo_if_verbose "$(ts) creating clair layer '${LAYER}'"

    BODY=$(mktemp 2> /dev/null || mktemp -t DAS)

    if [ "${PREVIOUS_LAYER}" == "" ]; then
        echo "{\"Layer\": {\"Name\": \"${LAYER}\", \"Path\": \"${DOCKER_IMAGE_EXPLODED_TAR_DIR}/${LAYER}/layer.tar\", \"Format\": \"Docker\"}}" > "${BODY}"
    else
        echo "{\"Layer\": {\"Name\": \"${LAYER}\", \"Path\": \"${DOCKER_IMAGE_EXPLODED_TAR_DIR}/${LAYER}/layer.tar\", \"ParentName\": \"${PREVIOUS_LAYER}\", \"Format\": \"Docker\"}}" > "${BODY}"
    fi

    if ! HTTP_STATUS_CODE=$(curl \
        -s \
        -X POST \
        -H 'Content-Type: application/json' \
        --data-binary @"${BODY}" \
        --write-out "%{http_code}" \
        --silent \
        --output /dev/null \
        "http://127.0.0.1:${CLAIR_API_PORT}/v1/layers") \
        || \
        [ "${HTTP_STATUS_CODE}" != "201" ];
    then
        echo "$(ts) error creating clair layer '${LAYER}'" >&2
        exit 1
    fi

    echo_if_verbose "$(ts) successfully created clair layer '${LAYER}'"

    PREVIOUS_LAYER=${LAYER}
done

echo_if_verbose "$(ts) done creating clair layers"

#
# Iterate through each layer in the saved image and use 
# Clair's RESTful API (https://coreos.com/clair/docs/latest/api_v1.html#vulnerabilities)
# to get the vulnerabilities for each layer.
#
echo_if_verbose "$(ts) starting to get vulnerabilities for clair layers"

VULNERABILTIES_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)

echo_if_verbose "$(ts) saving vulnerabilities to directory '${VULNERABILTIES_DIR}'"

for LAYER in ${LAYERS}
do
    echo_if_verbose "$(ts) getting vulnerabilities for layer '${LAYER}'"

    if ! HTTP_STATUS_CODE=$(curl \
        -s \
        -o "${VULNERABILTIES_DIR}/${LAYER}" \
        --write-out "%{http_code}" \
        --silent \
        --output /dev/null \
        "http://127.0.0.1:${CLAIR_API_PORT}/v1/layers/${LAYER}?vulnerabilities") \
        || \
        [ "${HTTP_STATUS_CODE}" != "200" ];
    then
        echo "$(ts) error getting vulnerabilities for layer '${LAYER}'" >&2
        exit 1
    fi

    echo_if_verbose "$(ts) successfully got vulnerabilities for layer '${LAYER}'"
done

echo_if_verbose "$(ts) done getting vulnerabilities for clair layers"

#
# ...
#
assess-vulnerabilities-risk.py "${LOG_LEVEL}" "${VULNERABILTIES_DIR}"

exit 0
