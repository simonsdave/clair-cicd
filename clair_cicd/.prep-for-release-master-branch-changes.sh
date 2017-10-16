#!/usr/bin/env bash

set -e

if [ $# != 0 ]; then
    echo "usage: $(basename "$0")" >&2
    exit 1
fi

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"
INIT_DOT_PY=$SCRIPT_DIR_NAME/__init__.py
CURRENT_VERSION=$(grep __version__ "$INIT_DOT_PY" | sed -e "s|^.*=\\s*['\"]||g" | sed -e "s|['\"].*$||g")
NEXT_VERSION=$(python -c "v = '$CURRENT_VERSION'.split('.'); v[1] = str(1 + int(v[1])); print '.'.join(v)")

sed \
    -i \
    -e "s|^\\s*__version__\\s*=\\s*['\"].*['\"]\\s*$|__version__ = '$NEXT_VERSION'|g" \
    "$INIT_DOT_PY"

exit 0
