#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

VERBOSE=0
TAG="latest"

while true
do
    OPTION=`echo ${1:-} | awk '{print tolower($0)}'`
    case "$OPTION" in
        -v)
            shift
            VERBOSE=1
            ;;
        -t)
            shift
            TAG=${1:-}
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ $# != 1 ] && [ $# != 3 ]; then
    echo "usage: `basename $0` [-v] [-t <tag>] <dockerhub-username> [<dockerhub-email> <dockerhub-password>]" >&2
    exit 1
fi

DOCKERHUB_USERNAME=${1:-}
DOCKERHUB_EMAIL=${2:-}
DOCKERHUB_PASSWORD=${3:-}

CLAIR_DATABASE_IMAGE_NAME=$DOCKERHUB_USERNAME/clair-database:$TAG

sudo docker pull postgres:9.5.2

CLAIR_DATABASE_CONTAINER_NAME=clair-database

sudo docker kill $CLAIR_DATABASE_CONTAINER_NAME >& /dev/null || true
sudo docker rm $CLAIR_DATABASE_CONTAINER_NAME >& /dev/null || true

sudo docker \
    run \
    --name $CLAIR_DATABASE_CONTAINER_NAME \
    -e 'PGDATA=/var/lib/postgresql/data-non-volume' \
    -p 5432:5432 \
    -d \
    postgres:9.5.2

echo -n 'Waiting for postgres to start '
for i in $(seq 1 10)
do
    sudo docker exec $CLAIR_DATABASE_CONTAINER_NAME sh -c 'echo "\list" | psql -U postgres' >& /dev/null
    if [ $? == 0 ]; then
        break
    fi
    echo -n '.'
    sleep 3
done
echo '.'

sudo docker \
    exec \
    $CLAIR_DATABASE_CONTAINER_NAME \
    sh -c 'echo "create database clair" | psql -U postgres'

# create clair configuration that will point clair @ the database we just created
CLAIR_CONFIG_DIR=$(mktemp -d 2> /dev/null || mktemp -d -t DAS)
CLAIR_CONFIG_YAML=$CLAIR_CONFIG_DIR/config.yaml

curl \
    -s \
    -o "$CLAIR_CONFIG_YAML" \
    -L \
    https://raw.githubusercontent.com/coreos/clair/master/config.example.yaml

# postgres connection string details
# http://www.postgresql.org/docs/9.5/static/libpq-connect.html#LIBPQ-CONNSTRING
sed \
    -i \
    -e 's|source:|source: postgresql://postgres@clair-database:5432/clair?sslmode=disable|g' \
    "$CLAIR_CONFIG_YAML"

sudo docker \
    pull \
    quay.io/coreos/clair:latest

CLAIR_CONTAINER_NAME=clair

sudo docker kill $CLAIR_CONTAINER_NAME >& /dev/null || true
sudo docker rm $CLAIR_CONTAINER_NAME >& /dev/null || true

sudo docker \
    run \
    -d \
    --name $CLAIR_CONTAINER_NAME \
    -p 6060-6061:6060-6061 \
    --link $CLAIR_DATABASE_CONTAINER_NAME:clair-database \
    -v /tmp:/tmp \
    -v $CLAIR_CONFIG_DIR:/config \
    quay.io/coreos/clair:latest \
    -config=/config/config.yaml

echo -n 'Waiting for vulnerabilities database update to finish '
while true
do
    sudo docker logs $CLAIR_CONTAINER_NAME | grep "updater: update finished" >& /dev/null
    if [ $? == 0 ]; then
        break
    fi
    echo -n '.'
    sleep 15
done
echo ''

sudo docker kill $CLAIR_CONTAINER_NAME
sudo docker rm $CLAIR_CONTAINER_NAME

sudo docker rmi $CLAIR_DATABASE_IMAGE_NAME >& /dev/null

sudo docker \
    commit \
    --change 'ENV PGDATA /var/lib/postgresql/data-non-volume' \
    --change='CMD ["postgres"]' \
    --change='EXPOSE 5432' \
    --change='ENTRYPOINT ["/docker-entrypoint.sh"]' \
    $CLAIR_DATABASE_CONTAINER_NAME \
    $CLAIR_DATABASE_IMAGE_NAME

if [ "$DOCKERHUB_EMAIL" != "" ]; then
    sudo docker login \
        --email="$DOCKERHUB_EMAIL" \
        --username="$DOCKERHUB_USERNAME" \
        --password="$DOCKERHUB_PASSWORD"
    sudo docker push $CLAIR_DATABASE_IMAGE_NAME
fi

sudo docker kill $CLAIR_DATABASE_CONTAINER_NAME
sudo docker rm $CLAIR_DATABASE_CONTAINER_NAME

exit 0
