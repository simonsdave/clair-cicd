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

set -x

DOCKER_IMAGE_TO_ANALYZE=${1:-}

# MY_IP_ADDRESS=$(ifconfig eth0 | grep "inet addr:" | cut -d : -f 2 | cut -d " " -f 1)
# analyze-local-images -endpoint "http://clair:6060" -my-address "$MY_IP_ADDRESS" $DOCKER_IMAGE_TO_ANALYZE
analyze-local-images $DOCKER_IMAGE_TO_ANALYZE

set +x

exit 0
