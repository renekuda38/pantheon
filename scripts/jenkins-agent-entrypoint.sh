#!/bin/bash
# Universal entrypoint script for Jenkins agents (both inbound and ubuntu)
# Fixes docker.sock permissions before starting agent

set -e

# Fix docker socket permissions (must run as root initially)
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Detect which agent type and run appropriately
# Drop privileges and run as jenkins user
if command -v jenkins-agent >/dev/null 2>&1; then
    # Inbound agent image (has jenkins-agent command built-in)
    exec jenkins-agent "$@"
else
    exec java -jar /home/jeknins/agent.jar "$@"
fi
    
