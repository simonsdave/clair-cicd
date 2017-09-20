#!/usr/bin/env bash

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <release-branch>" >&2
    exit 1
fi

RELEASE_BRANCH=${1:-}

search_and_replace() {
    if ! git diff --quiet "${2:-}"; then exit 1; fi
    sed -i -e "${1:-}" "${2:-}"
    if git diff --quiet "${2:-}"; then exit 2; fi
    return 0
}

search_and_replace \
    "s|\\?branch=master|?branch=$RELEASE_BRANCH|g" \
    "$SCRIPT_DIR_NAME/README.md"

exit 0
