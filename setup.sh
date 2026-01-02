#!/bin/bash

set -euo pipefail

# logging fuction
function log() 
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/.env" ]; then
  source "${SCRIPT_DIR}/.env"
else
  log ERROR "environment file .env not found in ${SCRIPT_DIR}!"
  exit 1
fi

# check for required environment variables for git configuration
if [ -z "${GIT_EMAIL:-}" ] || [ -z "${GIT_USERNAME:-}" ]; then
  log ERROR "GIT_EMAIL and GIT_USERNAME environment variables are not set!"

  echo -e "fill a .env file in $(dirname "${BASH_SOURCE[0]}") with the following content:\n\n"
  echo "    GIT_EMAIL=\"your-email@example.com\""
  echo -e "    GIT_USERNAME=\"Your Name\"\n\n"

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

mkdir -p ~/pantheon/{scripts,configs,logs,temp}
chmod 750 ~/pantheon/scripts ~/pantheon/logs

# configure git
log INFO "configuring git ..."

git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_USERNAME}"

touch ~/pantheon/.gitignore

# set environment variables
log INFO 'setting environment variables ...'

echo 'export EDITOR=vim' >> ~/.bashrc
echo 'export WORKSPACE=~/pantheon' >> ~/.bashrc

# completed
log SUCCESS 'setup completed!'

exit 0


# Verify each installation was successful