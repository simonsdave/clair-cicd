#!/usr/bin/env bash

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 4 ]; then
    echo "usage: $(basename "$0") <github username> <github email> <github public key> <github private key>" >&2
    exit 1
fi

DEV_ENV_VERSION=$(cat "$SCRIPT_DIR_NAME/dev-env-version.txt")

curl -s "https://raw.githubusercontent.com/simonsdave/dev-env/$DEV_ENV_VERSION/ubuntu/xenial/create_dev_env.sh" | bash -s -- "$@"

exit 0
