#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <image-name>" >&2
    exit 1
fi

CLAIR_DATABASE_IMAGE_NAME=${1:-}

REPO_ROOT_DIR=$(repo-root-dir.sh)

DOCKER_CONTAINER_NAME=$(openssl rand -hex 16)

DUMMY_DOCKER_CONTAINER_NAME=$(create-dummy-docker-container.sh)

IMAGE_NAME_TEMPLATE=$(grep FROM "${REPO_ROOT_DIR}/dev_env/Dockerfile.template" | sed -e "s|^FROM[[:space:]]*||g")
DEV_ENV_VERSION=$(cat "${REPO_ROOT_DIR}/dev_env/dev-env-version.txt")
IMAGE_NAME=${IMAGE_NAME_TEMPLATE//%DEV_ENV_VERSION%/${DEV_ENV_VERSION}}

IN_CONTAINER_SCRIPT_DIR_NAME=${SCRIPT_DIR_NAME//${REPO_ROOT_DIR}//app}

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
    /bin/bash -c "${IN_CONTAINER_SCRIPT_DIR_NAME}/_build-docker-image.sh ${CLAIR_DATABASE_IMAGE_NAME}"
EXIT_CODE=$?

docker container rm "${DUMMY_DOCKER_CONTAINER_NAME}" > /dev/null

exit ${EXIT_CODE}
