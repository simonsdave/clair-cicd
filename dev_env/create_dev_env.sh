#!/usr/bin/env bash

echo -n "$(tput bold)"
echo -n "github username> "
echo -n "$(tput sgr0)"
read FOR_VAGRANT_GITHUB_USERNAME

echo -n "$(tput bold)"
echo -n "github email> "
echo -n "$(tput sgr0)"
read FOR_VAGRANT_GITHUB_EMAIL

VAGRANT_GITHUB_USERNAME=$FOR_VAGRANT_GITHUB_USERNAME VAGRANT_GITHUB_EMAIL=$FOR_VAGRANT_GITHUB_EMAIL vagrant up

exit 0
