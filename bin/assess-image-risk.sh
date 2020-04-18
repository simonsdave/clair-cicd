#!/usr/bin/env bash

#
# This is a complex script. Part of the reason for this complexity is that
# the script is intened to transparently run on a developer's workstation
# and in a CircleCI pipeline. Below is an outline of the script's logic:
#
#   -- parse command line arguments
#   -- pull clair db docker image and spin up a container
#   -- per the pattern described @ https://circleci.com/docs/2.0/building-docker-images/#mounting-folders,
#      create a container in which Clair's configuration file is saved and
#      then subsequently this container will be used when Clair's container
#      is started
#   -- spin up the Clair container and run ```assess-image-risk.sh```
#      inside the container to complete the risk assessment
#

ts() {
    date "+%Y-%m-%d %k:%M:%S"
}

echo_if_verbose() {
    if [ "1" -eq "${VERBOSE:-0}" ]; then
        echo "$@" 
    fi
    return 0
}

#
# parse command line arguments
#
VERBOSE=0
IMAGE_ASSESS_RISK_VERBOSE_FLAG=-s
NO_PULL_DOCKER_IAMGES=0
VULNERABILITY_WHITELIST='json://{"ignoreSevertiesAtOrBelow": "medium"}'

#
# :TRICKY: if this configuration is changed be sure to also change
# .cut-release-release-branch-changes.sh
#
# :TODO: how do we ensure Clair version and database version are the same?
#
CLAIR_CICD_VERSION=latest
CLAIR_DATABASE_IMAGE=simonsdave/clair-cicd-database:${CLAIR_CICD_VERSION}
CLAIR_VERSION=$(docker run --rm "${CLAIR_DATABASE_IMAGE}" /bin/bash -c 'echo ${CLAIR_VERSION}')
CLAIR_IMAGE=simonsdave/clair-cicd-clair:${CLAIR_CICD_VERSION}

while true
do
    case "$(echo "${1:-}" | tr "[:upper:]" "[:lower:]")" in
        -v|--verbose)
            shift
            VERBOSE=1
            IMAGE_ASSESS_RISK_VERBOSE_FLAG=-v
            ;;
        -vv)
            shift
            VERBOSE=1
            IMAGE_ASSESS_RISK_VERBOSE_FLAG=-vv
            ;;
        -np|--no-pull)
            shift
            NO_PULL_DOCKER_IAMGES=1
            ;;
        -wl|--whitelist)
            shift
            VULNERABILITY_WHITELIST=${1:-}
            shift
            ;;
        --clair-docker-image)
            shift
            CLAIR_IMAGE=${1:-}
            shift
            ;;
        --clair-database-docker-image)
            shift
            CLAIR_DATABASE_IMAGE=${1:-}
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") [-v|-vv|-np] <docker image id>" >&2
    exit 1
fi

DOCKER_IMAGE_TO_ANALYZE=${1:-}

#
# pull image and spin up clair database
#
if [ "0" -eq "${NO_PULL_DOCKER_IAMGES:-0}" ]; then
    echo_if_verbose "$(ts) pulling clair database image '${CLAIR_DATABASE_IMAGE}'"
    if ! docker pull "${CLAIR_DATABASE_IMAGE}" > /dev/null; then
        echo "$(ts) error pulling clair database image '${CLAIR_DATABASE_IMAGE}'" >&2
        exit 1
    fi
    echo_if_verbose "$(ts) successfully pulled clair database image"
else
    echo_if_verbose "$(ts) **not** pulling clair database image '${CLAIR_DATABASE_IMAGE}'"
fi

CLAIR_DATABASE_CONTAINER=clair-db-$(openssl rand -hex 8)
echo_if_verbose "$(ts) starting clair database container '${CLAIR_DATABASE_CONTAINER}'"
if ! docker run --name "${CLAIR_DATABASE_CONTAINER}" -d "${CLAIR_DATABASE_IMAGE}" > /dev/null; then
    echo "$(ts) error starting clair database container '${CLAIR_DATABASE_CONTAINER}'" >&2
    exit 1
fi

echo_if_verbose -n "$(ts) waiting for database server in container '${CLAIR_DATABASE_CONTAINER}' to start "
while true
do
    if docker logs "${CLAIR_DATABASE_CONTAINER}" 2>&1 | grep "database system is ready to accept connections" > /dev/null; then
        break
    fi
    echo_if_verbose -n "."
    sleep 1
done
echo_if_verbose ""

echo_if_verbose "$(ts) successfully started clair database container"

#
# create and configure clair config container
#
# :TRICKY: motivation for creating this container is described in
# https://circleci.com/docs/2.0/building-docker-images/#mounting-folders
#
CLAIR_CONFIG_CONTAINER=clair-config-$(openssl rand -hex 8)

CLAIR_CONFIG_YAML=$(mktemp 2> /dev/null || mktemp -t DAS)
echo_if_verbose "$(ts) clair configuration in '${CLAIR_CONFIG_YAML}'"

curl \
    -s \
    -o "${CLAIR_CONFIG_YAML}" \
    -L \
    "https://raw.githubusercontent.com/coreos/clair/${CLAIR_VERSION}/config.example.yaml"

sed \
    -i \
    -e 's|source:.*$|source: postgresql://postgres@clair-database:5432/clair?sslmode=disable|g' \
    "${CLAIR_CONFIG_YAML}"

CLAIR_CONFIG_IMAGE=alpine:3.4

# explict pull to create opportunity to swallow stdout
docker pull "${CLAIR_CONFIG_IMAGE}" > /dev/null

docker create \
    -v /config \
    --name "${CLAIR_CONFIG_CONTAINER}" \
    "${CLAIR_CONFIG_IMAGE}" \
    /bin/true \
    > /dev/null

docker cp "${CLAIR_CONFIG_YAML}" "${CLAIR_CONFIG_CONTAINER}:/config/config.yaml"

#
# pull image and spin up clair
#
if [ "0" -eq "${NO_PULL_DOCKER_IAMGES:-0}" ]; then
    echo_if_verbose "$(ts) pulling clair image '${CLAIR_IMAGE}'"
    if ! docker pull "${CLAIR_IMAGE}" > /dev/null; then 
        echo "$(ts) error pulling clair image '${CLAIR_IMAGE}'" >&2
        exit 1
    fi
    echo_if_verbose "$(ts) successfully pulled clair image '${CLAIR_IMAGE}'"
else
    echo_if_verbose "$(ts) **not** pulling clair image '${CLAIR_IMAGE}'"
fi

#
# :TODO: need to derive the ports
# CLAIR_API_PORT @ .clair.api.port in ${CLAIR_CONFIG_YAML}
# CLAIR_HEALTH_API_PORT @ .clair.api.healthport in ${CLAIR_CONFIG_YAML}
CLAIR_API_PORT=6060
CLAIR_HEALTH_API_PORT=6061
# {"Event":"starting main API","Level":"info","Location":"api.go:52","Time":"2019-12-31 17:11:28.608914","port":6060}
# {"Event":"starting health API","Level":"info","Location":"api.go:85","Time":"2019-12-31 17:11:28.609998","port":6061}
#

#    -p "${CLAIR_API_PORT}":"${CLAIR_API_PORT}" \
#    -p "${CLAIR_HEALTH_API_PORT}":"${CLAIR_HEALTH_API_PORT}" \

CLAIR_CONTAINER=clair-$(openssl rand -hex 8)
echo_if_verbose "$(ts) starting clair container '${CLAIR_CONTAINER}'"
if ! docker run \
    -d \
    --name "${CLAIR_CONTAINER}" \
    --link "${CLAIR_DATABASE_CONTAINER}":clair-database \
    --volumes-from "${CLAIR_CONFIG_CONTAINER}" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${CLAIR_IMAGE}" \
    -log-level=debug \
    -config=/config/config.yaml \
    > /dev/null;
then
    echo "$(ts) error starting clair container '${CLAIR_CONTAINER}'" >&2
    exit 1
fi

#
# wait for Clair to start
#
while true
do
    HTTP_STATUS_CODE=$(docker exec "${CLAIR_CONTAINER}" curl -s --max-time 3 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${CLAIR_HEALTH_API_PORT}/health")
    if [ "200" == "${HTTP_STATUS_CODE}" ]; then
        break
    fi
    sleep 1
done

echo_if_verbose "$(ts) successfully started clair container '${CLAIR_CONTAINER}'"

#
# if the vulnerability whitelist is in a file copy the file into
# Clair container so it's accessible to assess-image-risk.sh
#
if [[ $VULNERABILITY_WHITELIST == file://* ]]; then
    VULNERABILITY_WHITELIST_IN_CONTAINER=/tmp/whitelist.json
    if ! docker cp "${VULNERABILITY_WHITELIST/file:\/\//}" "${CLAIR_CONTAINER}:${VULNERABILITY_WHITELIST_IN_CONTAINER}"; then
        echo "$(ts) error copying whitelist from '${VULNERABILITY_WHITELIST/file:\/\//}' to '${CLAIR_CONTAINER}:${VULNERABILITY_WHITELIST_IN_CONTAINER}'" >&2
        exit 1
    fi
    VULNERABILITY_WHITELIST=file://${VULNERABILITY_WHITELIST_IN_CONTAINER}
fi

#
# Now that the Clair container and Clair database container are started
# it's time to kick-off the process of assessing the image's risk.
#
docker exec "${CLAIR_CONTAINER}" assess-image-risk.sh --whitelist "${VULNERABILITY_WHITELIST}" --api-port "${CLAIR_API_PORT}" "${IMAGE_ASSESS_RISK_VERBOSE_FLAG}" "${DOCKER_IMAGE_TO_ANALYZE}"
EXIT_CODE=$?

#
# a little bit of cleanup
#
docker kill "${CLAIR_CONTAINER}" >& /dev/null
docker rm "${CLAIR_CONTAINER}" >& /dev/null

docker kill "${CLAIR_CONFIG_CONTAINER}" >& /dev/null
docker rm "${CLAIR_CONFIG_CONTAINER}" >& /dev/null

docker kill "${CLAIR_DATABASE_CONTAINER}" >& /dev/null
docker rm "${CLAIR_DATABASE_CONTAINER}" >& /dev/null

#
# we're all done:-)
#
exit "${EXIT_CODE}"
