#!/bin/bash
# Entrypoint script for Jenkins agent
# Fixes docker.sock permissions before starting agent

# Fix docker socket permissions (must run as root initially)
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Drop privileges and run jenkins-agent as jenkins user
# gosu replaces current process (like exec) and switches user
exec gosu jenkins jenkins-agent "$@"
