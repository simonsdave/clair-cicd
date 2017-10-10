#!/usr/bin/env bash

#
# prep-for-release-python.sh is a pythin specific wrapper around
# the general purpose prep-for-release.sh. To run prep-for-release.sh
# you need the release version number. For Python projects this
# version number can be extracted from the project __init__.py file.
#

set -e

echo_if_verbose() {
    if [ "1" -eq "${VERBOSE:-0}" ]; then
        echo "${1:-}"
    fi
    return 0
}

confirm_ok_to_proceed() {
    if [ "0" -eq "${QUIET:-0}" ]; then
        while true
        do
            read -p "${1:-} (y/n)> " -n 1 -r
            echo

            case "${REPLY,,}" in
                y)
                    break
                    ;;
                n)
                    exit 0
                    ;;
                *)
                    ;;
            esac
        done
    fi
    return 0
}

VERBOSE=0

while true
do
    case "${1,,}" in
        --verbose)
            shift
            VERBOSE=1
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 0 ]; then
    echo "usage: $(basename "$0") [--verbose]" >&2
    exit 1
fi

REPO_ROOT_DIR=$(git rev-parse --show-toplevel)
REPO=$(basename "$REPO_ROOT_DIR")
INIT_DOT_PY=$REPO_ROOT_DIR/${REPO//-/_}/__init__.py
CURRENT_VERSION=$(grep __version__ "$INIT_DOT_PY" | sed -e "s|^.*=\\s*['\"]||g" | sed -e "s|['\"].*$||g")

prep-for-release.sh "$CURRENT_VERSION"

exit 0
