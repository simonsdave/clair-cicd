#!/usr/bin/env bash
#
# this script automates the process of building a postgress docker
# image that runs postgres and contains a fully populated database
# of current vulnerabilities.
#

# :TODO: really don't like the way these timestamp(ts) echo functions
# are implemented. Has to be a cleaner way to code these.
ts() {
    date "+%Y-%m-%d %k:%M:%S"
}

ts_echo() {
    if [ "${1:-}" == "-n" ]; then
        echo -n "$(ts) ${2:-}"
    else
        echo "$(ts) ${1:-}"
    fi
    return 0
}

ts_echo_stderr() {
    echo "$(ts) ${1:-}" >&2
    return 0
}

create_clair_config_container() {
    local CLAIR_VERSION=${1:-}
    local POSTGRES_DB=${2:-}

    local CLAIR_CONFIG_DIR
    CLAIR_CONFIG_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)

    local CLAIR_CONFIG_YAML
    CLAIR_CONFIG_YAML=${CLAIR_CONFIG_DIR}/config.yaml

    curl \
        -s \
        -o "${CLAIR_CONFIG_YAML}" \
        -L \
        "https://raw.githubusercontent.com/coreos/clair/${CLAIR_VERSION}/config.example.yaml"

    # postgres connection string details
    # http://www.postgresql.org/docs/12.1/static/libpq-connect.html#LIBPQ-CONNSTRING
    sed \
        -i \
        -e "s|source:.*$|source: postgresql://postgres@clair-database:5432/${POSTGRES_DB}?sslmode=disable|g" \
        "${CLAIR_CONFIG_YAML}"

    local DUMMY_CONTAINER_NAME
    DUMMY_CONTAINER_NAME=$(openssl rand -hex 8)

    # explict pull to create opportunity to swallow stdout
    docker pull alpine:3.4 > /dev/null

    docker create \
        -v /config \
        --name "${DUMMY_CONTAINER_NAME}" \
        alpine:3.4 \
        /bin/true \
        > /dev/null

    docker cp "${CLAIR_CONFIG_YAML}" "${DUMMY_CONTAINER_NAME}:/config/."

    rm -rf "${CLAIR_CONFIG_DIR}"

    echo "${DUMMY_CONTAINER_NAME}"
}

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <image-name>" >&2
    exit 1
fi

CLAIR_DATABASE_IMAGE_NAME=${1:-}

# https://quay.io/repository/coreos/clair?tab=tags
CLAIR_VERSION=$(grep '^__clair_version__' "$(repo-root-dir.sh)/$(repo.sh -u)/__init__.py" | sed -e "s|^.*=[[:space:]]*['\"]||g" | sed -e "s|['\"].*$||g")
CLAIR_IMAGE_NAME=quay.io/coreos/clair:${CLAIR_VERSION}
CLAIR_CONTAINER_NAME=clair-$(openssl rand -hex 8)
CLAIR_DATABASE_CONTAINER_NAME=clair-database-$(openssl rand -hex 8)

POSTGRES_VERSION=$(grep '^__postgres_version__' "$(repo-root-dir.sh)/$(repo.sh -u)/__init__.py" | sed -e "s|^.*=[[:space:]]*['\"]||g" | sed -e "s|['\"].*$||g")
POSTGRES_DOCKER_IMAGE=postgres:${POSTGRES_VERSION}
POSTGRES_DB=clair

ts_echo "pulling database server docker image ${POSTGRES_DOCKER_IMAGE}"

if ! docker pull "${POSTGRES_DOCKER_IMAGE}" >& /dev/null; then
    ts_echo_stderr "error pulling database server docker image ${POSTGRES_DOCKER_IMAGE}"
    exit 1
fi

ts_echo "successfully pulled database server docker image"

ts_echo "starting database server container '${CLAIR_DATABASE_CONTAINER_NAME}'"
docker \
    run \
    --name "${CLAIR_DATABASE_CONTAINER_NAME}" \
    -e "PGDATA=/var/lib/postgresql/data-non-volume" \
    -e "POSTGRES_DB=${POSTGRES_DB}" \
    -d \
    "${POSTGRES_DOCKER_IMAGE}" \
    > /dev/null
ts_echo "successfully started database server container"

ts_echo -n "waiting for database server in container '${CLAIR_DATABASE_CONTAINER_NAME}' to start "
for i in $(seq 1 10)
do
    if ! docker logs "${CLAIR_DATABASE_CONTAINER_NAME}" |& grep "database system is ready to accept connections" > /dev/null; then
        break
    fi
    echo -n "."
    sleep 3
done
echo ''

ts_echo "successfully started database server from docker image '${POSTGRES_DOCKER_IMAGE}'"

ts_echo -n "creating database "

MAX_NUM_DATABASE_CREATE_ATTEMPTS=10
for i in $(seq 1 ${MAX_NUM_DATABASE_CREATE_ATTEMPTS})
do
    if docker \
        exec \
         "${CLAIR_DATABASE_CONTAINER_NAME}" \
         sh -c "psql -U postgres -c '\list'" |& \
         grep "^\s*${POSTGRES_DB}" \
         >& /dev/null;
    then
        echo ""
        break
    fi

    echo -n "."

    sleep 3
done
if [ "$i" == "${MAX_NUM_DATABASE_CREATE_ATTEMPTS}" ]; then
    echo ""
    ts_echo "error creating database"
    exit 1
fi

ts_echo "successfully created database"

#
# get clair running
#
ts_echo "pulling clair image '${CLAIR_IMAGE_NAME}'"
if ! docker pull "${CLAIR_IMAGE_NAME}" > /dev/null; then
    ts_echo_stderr "error pulling clair image '${CLAIR_IMAGE_NAME}'"
    exit 1
fi
ts_echo "pulled clair image '${CLAIR_IMAGE_NAME}'"

#
# create clair configuration that will point clair @ the database we just created
#
ts_echo "creating clair configuration container"
CLAIR_CONFIG_CONTAINER_NAME=$(create_clair_config_container "${CLAIR_VERSION}" "${POSTGRES_DB}")
ts_echo "created clair configuration container '${CLAIR_CONFIG_CONTAINER_NAME}'"

ts_echo "creating clair container '${CLAIR_CONTAINER_NAME}'"
if ! docker \
    run \
    -d \
    --name "${CLAIR_CONTAINER_NAME}" \
    --volumes-from "${CLAIR_CONFIG_CONTAINER_NAME}:ro" \
    --link "${CLAIR_DATABASE_CONTAINER_NAME}":clair-database \
    -v /tmp:/tmp \
    "${CLAIR_IMAGE_NAME}" \
    -config=/config/config.yaml \
    > /dev/null;
then
    ts_echo_stderr "error creating clair container '${CLAIR_CONTAINER_NAME}'"
    exit 1
fi
ts_echo "successfully created clair container"

ts_echo -n "waiting for vulnerabilities database update to finish "
while true
do
    if docker logs "${CLAIR_CONTAINER_NAME}" | grep 'update finished' >& /dev/null; then
        break
    fi

    if docker logs "${CLAIR_CONTAINER_NAME}" | grep 'an error occured' >& /dev/null; then
        if ! docker logs "${CLAIR_CONTAINER_NAME}" | grep 'an error occured.*received 404 code downloading' >& /dev/null; then
            echo ""
            ts_echo_stderr "error during vulnerabilities database update try 'docker logs ${CLAIR_CONTAINER_NAME}'"
            ts_echo_stderr "------------------------------------------------------------"
            docker logs "${CLAIR_CONTAINER_NAME}"
            ts_echo_stderr "------------------------------------------------------------"
            exit 1
        fi
    fi

    echo -n "."
    sleep 15
done
echo ""

# make sure the namespaces for which we didn't get vulnerabilities is really clear
if docker logs "${CLAIR_CONTAINER_NAME}" | grep 'an error occured.*received 404 code downloading' >& /dev/null; then
    ts_echo "------------------------------------------------------------"
    ts_echo "failed to retrieve vulnerabilities for following namespaces"
    ts_echo "------------------------------------------------------------"
    docker logs "${CLAIR_CONTAINER_NAME}" | grep 'an error occured.*received 404 code downloading'
    ts_echo "------------------------------------------------------------"
else
    ts_echo "successfully retrieved vulnerabilities for all namespaces"
fi

# sanity check on the # of vulnerabilities we did retrieve
ts_echo "------------------------------------------------------------"
ts_echo "Vulnerability Summary"
ts_echo "------------------------------------------------------------"

docker \
    exec \
    "${CLAIR_DATABASE_CONTAINER_NAME}" \
    sh -c "psql -U postgres -d ${POSTGRES_DB} -c 'SELECT n.name AS namespace, count(*) AS number_vulnerabilities FROM vulnerability AS v, namespace AS n WHERE v.namespace_id = n.id group by n.name order by n.name'"

ts_echo "------------------------------------------------------------"

ts_echo -n "vulnerabilities database update finish"

# :TODO: describe what's happening in this next section

docker kill "${CLAIR_CONTAINER_NAME}" > /dev/null
docker rm "${CLAIR_CONTAINER_NAME}" > /dev/null

docker rmi "${CLAIR_DATABASE_IMAGE_NAME}" >& /dev/null

docker \
    commit \
    --change "ENV CLAIR_VERSION ${CLAIR_VERSION}" \
    --change 'ENV PGDATA /var/lib/postgresql/data-non-volume' \
    --change='CMD ["postgres"]' \
    --change='EXPOSE 5432' \
    --change='ENTRYPOINT ["/docker-entrypoint.sh"]' \
    "${CLAIR_DATABASE_CONTAINER_NAME}" \
    "${CLAIR_DATABASE_IMAGE_NAME}" \
    > /dev/null

docker kill "${CLAIR_DATABASE_CONTAINER_NAME}" > /dev/null
docker rm "${CLAIR_DATABASE_CONTAINER_NAME}" > /dev/null

docker rm "${CLAIR_CONFIG_CONTAINER_NAME}" > /dev/null

ts_echo "done!"

exit 0
