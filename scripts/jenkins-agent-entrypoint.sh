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
    exec gosu jenkins jenkins-agent "$@"
else
    # Custom ubuntu agent - download agent.jar if not present
    AGENT_JAR="/home/jenkins/agent.jar"
    JENKINS_URL="${JENKINS_URL:-http://jenkins-master:8080}"

    if [ ! -f "$AGENT_JAR" ] || [ ! -s "$AGENT_JAR" ]; then
        echo "Downloading Jenkins agent JAR from ${JENKINS_URL}..."
        curl -fsSL -o "$AGENT_JAR" "${JENKINS_URL}/jnlpJars/agent.jar"
        chown jenkins:jenkins "$AGENT_JAR"

        # Validate download
        JAR_SIZE=$(stat -c %s "$AGENT_JAR" 2>/dev/null || stat -f %z "$AGENT_JAR")
        if [ "$JAR_SIZE" -lt 1000000 ]; then
            echo "ERROR: agent.jar is too small (${JAR_SIZE} bytes), download likely failed"
            exit 1
        fi
        echo "Downloaded agent.jar (${JAR_SIZE} bytes)"
    fi

    exec gosu jenkins java -jar "$AGENT_JAR" "$@"
fi
