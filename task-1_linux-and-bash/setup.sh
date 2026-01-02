#!/bin/bash

set -euo pipfail

# logging fuction
function log(): 
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"

# check for required environment variables for git configuration
if [ -z "${GIT_EMAIL:-}" ] || [ -z "${GIT_USERNAME:-}" ]; then
  log ERROR "GIT_EMAIL and GIT_USERNAME environment variables are not set!"

  echo -e "create a .env file in $(dirname "$(dirname "${BASH_SOURCE[0]}")") with the following content:\n\n"
  echo "GIT_EMAIL=\"your-email@example.com\""
  echo -e "GIT_USERNAME=\"Your Name\"\n\n"
  echo "Then run: source .env before executing this script"

  exit 1
fi

# check for root privileges
if [ "${EUID}" -ne 0 ]; then
  echo '[ERROR] root privilages required!'
  echo "usage: sudo $0"  
  exit 1
fi

# start setup
log INFO 'setup has been started ...'

# update package index
log INFO 'updating package index ...'

apt-get update -qq

# install required packages
log INFO 'installing required packages ...'

apt-get install -y -qq \
  curl \
  wget \
  git \
  vim \
  jq \
  tree \
  htop \
  net-tools

# create directory structure
log INFO 'creating directory structure ...'

mkdir -p ~/pantheon_tech/{scripts,configs,logs,temp}
chmod 750 ~/pantheon_tech/scripts

# configure git
log INFO "configuring git ..."

git config --global user.email "${GIT_EMAIL}"
git config -—global user.name "${GIT_USERNAME}"

touch ~/pantheon/.gitignore

# set environment variables
log INFO 'setting environment variables ...'

echo 'export EDITOR=vim' >> ~/.bashrc
echo 'export WORKSPACE=~/pantheon_tech' >> ~/.bashrc

# completed
log SUCCESS 'setup completed!'

exit 0


# Verify each installation was successful