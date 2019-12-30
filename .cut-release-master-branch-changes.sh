#!/usr/bin/env bash

#
# increment the project's version number
#

set -e

if [ $# != 0 ]; then
    echo "usage: $(basename "$0")" >&2
    exit 1
fi

INIT_DOT_PY=$(repo-root-dir.sh)/$(repo.sh -u)/__init__.py
CURRENT_VERSION=$(grep __version__ "$INIT_DOT_PY" | sed -e "s|^.*=[[:space:]]*['\"]||g" | sed -e "s|['\"].*$||g")

# the pip install below is necessary make it super simple
# to figure out the project's next version
pip3 install semantic-version > /dev/null

NEXT_VERSION=$(python -c "import semantic_version; print(semantic_version.Version('$CURRENT_VERSION').next_minor())")

sed -i '' -e "s|^[[:space:]]*__version__[[:space:]]*=[[:space:]]*['\"]${CURRENT_VERSION}['\"][[:space:]]*$|__version__ = '${NEXT_VERSION}'|g" "${INIT_DOT_PY}"

exit 0
