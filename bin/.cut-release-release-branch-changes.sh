#!/usr/bin/env bash

# :TODO: this is a placeholder intended to update assess-image-risk.sh
# and more specifically the 'latest' part of 'CLAIR_CICD_VERSION=latest'
# to the required release branch

set -e

# SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <release-branch>" >&2
    exit 1
fi

# RELEASE_BRANCH=${1:-}

exit 0
