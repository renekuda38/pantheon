#!/bin/bash 

set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"


# logging fuction
function log()
{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
}


# heathcheck function
function check_jenkins()
{
    local url="$1"

    log INFO "checking Jenkins health at ${url} ..."

    # curl with timeout and fail on HTTP errors
    if curl -sf --max-time 5 "${url}" > /dev/null 2>&1; then
        log SUCCESS "Jenkins is healthy and reachable at ${url}"
        return 0
    else 
        log ERROR "Jenkins is not responding at ${url}"
        return 1
    fi
}

# perform healthcheck
log INFO "starting Jenkins healthcheck ..."

if check_jenkins "${JENKINS_URL}"; then
    log INFO "Jenkins healthcheck completed successfully."
    exit 0
else
    log ERROR "Jenkins healthcheck failed."
    exit 1
fi