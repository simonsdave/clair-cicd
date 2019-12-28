#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <image-name>" >&2
    exit 1
fi

CLAIR_DATABASE_IMAGE_NAME=${1:-}

DOCKER_CONTAINER_NAME=$(python3.7 -c "import uuid; print(uuid.uuid4().hex)")

DUMMY_DOCKER_CONTAINER_NAME=$(create-dummy-docker-container.sh)

IMAGE_NAME_TEMPLATE=$(cat "$(repo-root-dir.sh)/dev_env/Dockerfile.template" | grep FROM | sed -e "s|^FROM[[:space:]]*||g")
DEV_ENV_VERSION=$(cat "$(repo-root-dir.sh)/dev_env/dev-env-version.txt")
IMAGE_NAME=$(echo "${IMAGE_NAME_TEMPLATE}" | sed -e "s|%DEV_ENV_VERSION%|${DEV_ENV_VERSION}|g")

IN_CONTAINER_SCRIPT_DIR_NAME=$(echo "${SCRIPT_DIR_NAME}" | sed -e "s|$(repo-root-dir.sh)|/app|g")

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

docker container rm "${DUMMY_DOCKER_CONTAINER_NAME}" > /dev/null

exit 0
