#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 2 ]; then
    echo "usage: $(basename "$0") <package> <image-name>" >&2
    exit 1
fi

PACKAGE=${1:-}
CLAIR_CICD_TOOLS_IMAGE_NAME=${2:-}

REPO_ROOT_DIR=$(repo-root-dir.sh)

IN_CONTAINER_PACKAGE=$(python3.7 -c "import os; print(os.path.abspath('${PACKAGE}').replace('${REPO_ROOT_DIR}', '/app'))")
if [[ "${PACKAGE}" == "${IN_CONTAINER_PACKAGE}" ]]; then
    echo "'${PACKAGE}' must be in '${REPO_ROOT_DIR}' or a sub-directory of '${REPO_ROOT_DIR}'" >&2
    exit 1
fi

DOCKER_CONTAINER_NAME=$(python3.7 -c "import uuid; print(uuid.uuid4().hex)")

DUMMY_DOCKER_CONTAINER_NAME=$(create-dummy-docker-container.sh)

IMAGE_NAME_TEMPLATE=$(grep FROM "${REPO_ROOT_DIR}/dev_env/Dockerfile.template" | sed -e "s|^FROM[[:space:]]*||g")
DEV_ENV_VERSION=$(cat "${REPO_ROOT_DIR}/dev_env/dev-env-version.txt")
IMAGE_NAME=${IMAGE_NAME_TEMPLATE//%DEV_ENV_VERSION%/${DEV_ENV_VERSION}}

IN_CONTAINER_SCRIPT_DIR_NAME=$(python3.7 -c "print('${SCRIPT_DIR_NAME}'.replace('${REPO_ROOT_DIR}', '/app'))")

#
# --volumes-from below implements the pattern described @ https://circleci.com/docs/2.0/building-docker-images/#mounting-folders
# -v below comes from https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/
#

docker run \
    --rm \
    --name "${DOCKER_CONTAINER_NAME}" \
    --volumes-from "${DUMMY_DOCKER_CONTAINER_NAME}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${IMAGE_NAME}" \
    /bin/bash -c "${IN_CONTAINER_SCRIPT_DIR_NAME}/_build-docker-image.sh '${IN_CONTAINER_PACKAGE}' '${CLAIR_CICD_TOOLS_IMAGE_NAME}'"

docker container rm "${DUMMY_DOCKER_CONTAINER_NAME}" > /dev/null

exit 0
