#!/usr/bin/env bash
#
# this script provisions the project's development environment
#

set -e

apt-get update -y

apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" | tee /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-engine
usermod -aG docker vagrant
service docker restart

apt-get install -y git

timedatectl set-timezone EST

curl -s -L --output /usr/local/bin/jq 'https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64'
chown root.root /usr/local/bin/jq
chmod a+x /usr/local/bin/jq

apt-get install -y python-virtualenv
apt-get install -y python-dev

# instructions from https://cloud.google.com/sdk/#debubu
export CLOUD_SDK_REPO=cloud-sdk-`lsb_release -c -s`
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update && apt-get install google-cloud-sdk

cp /vagrant/.vimrc ~vagrant/.vimrc
chown vagrant:vagrant ~vagrant/.vimrc

echo 'export VISUAL=vim' >> ~vagrant/.profile
echo 'export EDITOR="$VISUAL"' >> ~vagrant/.profile

if [ $# == 2 ]; then
    su - vagrant -c "git config --global user.name \"${1:-}\""
    su - vagrant -c "git config --global user.email \"${2:-}\""
fi

exit 0
