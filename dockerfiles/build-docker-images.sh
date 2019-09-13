#!/usr/bin/env bash
#
# This script builds all docker images
#

set -e

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

if [ $# != 3 ]; then
    echo "usage: $(basename "$0") <username> <tag> <package-tar-gz>" >&2
    exit 1
fi

USERNAME=${1:-}
TAG=${2:-}
PACKAGE_TAR_GZ=${3:-}

if [ "${DEV_ENV_DOCKER_IMAGE}" != "" ]; then
    #
    # :TODO: do we really need to create a dummy container
    # if this path is only going to be used in a development
    # environment
    #
    DUMMY_DOCKER_CONTAINER_NAME=$(create-dummy-docker-container.sh)

    DOCKER_CONTAINER_NAME=$(python -c "import uuid; print uuid.uuid4().hex")

    PACKAGE_TAR_GZ=$(pushd "${SCRIPT_DIR_NAME}/../dist" > /dev/null && ls clair-cicd-*.*.*.tar.gz && popd > /dev/null)

    #
    # the -v below comes from https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/
    #
    # with this the docker cli which runs inside container will talk with the docker daemon
    # running on the host - this path is only expected to run in a development environment
    #
    docker run \
        --name "${DOCKER_CONTAINER_NAME}" \
        --volumes-from "${DUMMY_DOCKER_CONTAINER_NAME}" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        "${DEV_ENV_DOCKER_IMAGE}" \
        /bin/bash -c "/app/dockerfiles/build-docker-images.sh '${USERNAME}' '${TAG}' '/app/dist/${PACKAGE_TAR_GZ}'"

    docker container rm "${DOCKER_CONTAINER_NAME}" > /dev/null

    docker container rm "${DUMMY_DOCKER_CONTAINER_NAME}" > /dev/null

    exit 0
fi

"${SCRIPT_DIR_NAME}/cicd-tools/build-docker-image.sh" \
    "$USERNAME" \
    "$TAG" \
    "$PACKAGE_TAR_GZ"

"${SCRIPT_DIR_NAME}/database/build-docker-image.sh" \
    "$USERNAME" \
    "$TAG"

exit 0
