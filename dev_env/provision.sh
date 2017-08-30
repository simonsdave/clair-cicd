#!/usr/bin/env bash
#
# this script provisions the project's development environment
#

set -e

#
# install basic python dev env
#
apt-get install -y python-virtualenv
apt-get install -y python-dev

exit 0
