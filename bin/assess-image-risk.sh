#!/usr/bin/env bash

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
VERBOSE_FLAG=""
NO_PULL_DB_AND_TOOLS_DOCKER_IMAGES=0

while true
do
    case "${1,,}" in
        -v)
            shift
            VERBOSE=1
            VERBOSE_FLAG=--log=info
            ;;
        -vv)
            shift
            VERBOSE=1
            VERBOSE_FLAG=--log=debug
            ;;
        -np)
            shift
            NO_PULL_DB_AND_TOOLS_DOCKER_IMAGES=1
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
# general configuration
#
# :TODO: clair database version & clair version should match
CLAIR_DATABASE_IMAGE=simonsdave/clair-cicd-database:latest
CLAIR_VERSION=$(python -c "import clair_cicd; print clair_cicd.__clair_version__")
CLAIR_IMAGE=quay.io/coreos/clair:$CLAIR_VERSION
# :TODO: should not be latest version
CLAIR_CICD_TOOLS_IMAGE=simonsdave/clair-cicd-tools:latest

#
# pull image and spin up clair database
#
if [ "0" -eq "${NO_PULL_DB_AND_TOOLS_DOCKER_IMAGES:-0}" ]; then
    echo_if_verbose "$(ts) pulling clair database image '$CLAIR_DATABASE_IMAGE'"
    if ! docker pull $CLAIR_DATABASE_IMAGE > /dev/null; then
        echo "$(ts) error pulling clair database image '$CLAIR_DATABASE_IMAGE'" >&2
        exit 1
    fi
    echo_if_verbose "$(ts) successfully pulled clair database image"
else
    echo_if_verbose "$(ts) **not** pulling clair database image '$CLAIR_DATABASE_IMAGE'"
fi

CLAIR_DATABASE_CONTAINER=clair-db-$(openssl rand -hex 8)
echo_if_verbose "$(ts) starting clair database container '$CLAIR_DATABASE_CONTAINER'"
if ! docker run --name "$CLAIR_DATABASE_CONTAINER" -d "$CLAIR_DATABASE_IMAGE" > /dev/null; then
    echo "$(ts) error starting clair database container '$CLAIR_DATABASE_CONTAINER'" >&2
    exit 1
fi

echo_if_verbose -n "$(ts) waiting for database server in container '$CLAIR_DATABASE_CONTAINER' to start "
while true
do
    if docker logs "$CLAIR_DATABASE_CONTAINER" |& grep "database system is ready to accept connections" > /dev/null; then
        break
    fi
    echo_if_verbose -n "."
    sleep 1
done
echo_if_verbose ""

echo_if_verbose "$(ts) successfully started clair database container"

#
# pull image and spin up clair
#
CLAIR_CONFIG_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
CLAIR_CONFIG_YAML=$CLAIR_CONFIG_DIR/config.yaml
echo_if_verbose "$(ts) clair configuration in '$CLAIR_CONFIG_YAML'"

curl \
    -s \
    -o "$CLAIR_CONFIG_YAML" \
    -L \
    "https://raw.githubusercontent.com/coreos/clair/$CLAIR_VERSION/config.example.yaml"

sed \
    -i \
    -e 's|source:.*$|source: postgresql://postgres@clair-database:5432/clair?sslmode=disable|g' \
    "$CLAIR_CONFIG_YAML"

echo_if_verbose "$(ts) pulling clair image '$CLAIR_IMAGE'"
if ! docker pull "$CLAIR_IMAGE" > /dev/null; then 
    echo "$(ts) error pulling clair image '$CLAIR_IMAGE'" >&2
    exit 1
fi
echo_if_verbose "$(ts) successfully pulled clair image"

CLAIR_CONTAINER=clair-$(openssl rand -hex 8)
echo_if_verbose "$(ts) starting clair container '$CLAIR_CONTAINER'"
if ! docker run \
    -d \
    --name "$CLAIR_CONTAINER" \
    -p 6060-6061:6060-6061 \
    --link "$CLAIR_DATABASE_CONTAINER":clair-database \
    -v /tmp:/tmp \
    -v "$CLAIR_CONFIG_DIR":/config \
    "$CLAIR_IMAGE" \
    -log-level=info \
    -config=/config/config.yaml \
    > /dev/null;
then
    echo "$(ts) error starting clair container '$CLAIR_CONTAINER'" >&2
    exit 1
fi

# :TODO: should not be hard coding port number
CLAIR_IP_ADDRESS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$CLAIR_CONTAINER")
CLAIR_ENDPOINT=http://$CLAIR_IP_ADDRESS:6060
CLAIR_HEALTH_ENDPOINT=http://$CLAIR_IP_ADDRESS:6061

while true
do
    HTTP_STATUS_CODE=$(curl -s -o /dev/null -w '%{http_code}' "$CLAIR_HEALTH_ENDPOINT/health")
    if [ "200" == "$HTTP_STATUS_CODE" ]; then
        break
    fi
    sleep 1
done

echo_if_verbose "$(ts) successfully started clair container '$CLAIR_CONTAINER'"

#
#
#
DOCKER_IMAGE_EXPLODED_TAR_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
echo_if_verbose "$(ts) saving docker image '$DOCKER_IMAGE_TO_ANALYZE' to '$DOCKER_IMAGE_EXPLODED_TAR_DIR'"
pushd "$DOCKER_IMAGE_EXPLODED_TAR_DIR" > /dev/null || echo "only here to avoid shellcheck's SC2164"
docker save "$DOCKER_IMAGE_TO_ANALYZE" | tar xv > /dev/null
popd > /dev/null || echo "only here to avoid shellcheck's SC2164"
LAYERS=$(jq ".[0].Layers[]" < "$DOCKER_IMAGE_EXPLODED_TAR_DIR/manifest.json" | sed -e 's|"||g' | sed -e 's|/layer.tar$||g')
echo_if_verbose "$(ts) successfully saved docker image '$DOCKER_IMAGE_TO_ANALYZE'"

#
#
#
PREVIOUS_LAYER=""
for LAYER in $LAYERS
do
    echo_if_verbose "$(ts) creating clair layer '$LAYER'"

    BODY=$(mktemp 2> /dev/null || mktemp -t DAS)

    if [ "$PREVIOUS_LAYER" == "" ]; then
        echo "{\"Layer\": {\"Name\": \"$LAYER\", \"Path\": \"$DOCKER_IMAGE_EXPLODED_TAR_DIR/$LAYER/layer.tar\", \"Format\": \"Docker\"}}" > "$BODY"
    else
        echo "{\"Layer\": {\"Name\": \"$LAYER\", \"Path\": \"$DOCKER_IMAGE_EXPLODED_TAR_DIR/$LAYER/layer.tar\", \"ParentName\": \"$PREVIOUS_LAYER\", \"Format\": \"Docker\"}}" > "$BODY"
    fi

    # :TODO: might need to add a retry loop around this cURL statement as it
    # seems to fail every now and again:-(
    ERROR_OUTPUT=$(mktemp 2> /dev/null || mktemp -t DAS)

    if ! HTTP_STATUS_CODE=$(curl \
        -s \
        -o "$ERROR_OUTPUT" \
        -X POST \
        -H 'Content-Type: application/json' \
        -w '%{http_code}' \
        --data-binary @"$BODY" \
        "$CLAIR_ENDPOINT/v1/layers") \
        || \
        [ "$HTTP_STATUS_CODE" != "201" ];
    then
        echo "$(ts) error creating clair layer '$LAYER' - see errors @ '$ERROR_OUTPUT'" >&2
        exit 1
    fi

    PREVIOUS_LAYER=$LAYER

    echo_if_verbose "$(ts) successfully created clair layer '$LAYER'"
done

#
#
#
VULNERABILTIES_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)

echo_if_verbose "$(ts) saving vulnerabilities to directory '$VULNERABILTIES_DIR'"

for LAYER in $LAYERS
do
    if ! HTTP_STATUS_CODE=$(curl \
        -s \
        -o "$VULNERABILTIES_DIR/$LAYER" \
        -w '%{http_code}' \
        "$CLAIR_ENDPOINT/v1/layers/$LAYER?vulnerabilities") \
        || \
        [ "$HTTP_STATUS_CODE" != "200" ];
    then
        echo "$(ts) error getting vulnerabilities for layer '$LAYER'" >&2
        exit 1
    fi
done

#
# pull and spin up ci/cd tools
#
if [ "0" -eq "${NO_PULL_DB_AND_TOOLS_DOCKER_IMAGES:-0}" ]; then
    echo_if_verbose "$(ts) pulling clair ci/cd tools image '$CLAIR_CICD_TOOLS_IMAGE'"
    if ! docker pull "$CLAIR_CICD_TOOLS_IMAGE" > /dev/null; then
        echo "$(ts) error pulling clair image '$CLAIR_CICD_TOOLS_IMAGE'" >&2
        exit 1
    fi
    echo_if_verbose "$(ts) successfully pulled clair ci/cd tools image"
else
    echo_if_verbose "$(ts) **not** pulling clair ci/cd tools image '$CLAIR_CICD_TOOLS_IMAGE'"
fi

CLAIR_CICD_TOOLS_CONTAINER=clair-cicd-tools-$(openssl rand -hex 8)
docker \
    run \
    --name "$CLAIR_CICD_TOOLS_CONTAINER" \
    -v "$VULNERABILTIES_DIR":/vulnerabilities \
    "$CLAIR_CICD_TOOLS_IMAGE" \
    assess-vulnerabilities-risk.py $VERBOSE_FLAG /vulnerabilities

EXIT_CODE=$(docker inspect --format '{{ .State.ExitCode }}' "$CLAIR_CICD_TOOLS_CONTAINER")

#
# a little bit of cleanup
#
docker kill "$CLAIR_CICD_TOOLS_CONTAINER" >& /dev/null
docker rm "$CLAIR_CICD_TOOLS_CONTAINER" >& /dev/null

docker kill "$CLAIR_CONTAINER" >& /dev/null
docker rm "$CLAIR_CONTAINER" >& /dev/null

docker kill "$CLAIR_DATABASE_CONTAINER" >& /dev/null
docker rm "$CLAIR_DATABASE_CONTAINER" >& /dev/null

#
# we're all done:-)
#
exit "$EXIT_CODE"
