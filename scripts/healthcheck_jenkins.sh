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
    HTTP_STATUS=$(curl -f -s --max-time 5 -w "%{http_code}" -o /dev/null "${url}") || URL_EXIT_CODE=$?
    CURL_EXIT_CODE=${URL_EXIT_CODE:-0}

    if [ "${CURL_EXIT_CODE}" -ne 0 ]; then
        log ERROR "failed to connect to Jenkins at ${url}) (curl exit code: ${CURL_EXIT_CODE})"
        echo ""
        log ERROR "Jenkins healthcheck failed."
        exit 1
    fi

    if [ "${HTTP_STATUS}" -eq 200 ]; then
        log SUCCESS "Jenkins is healthy and reachable at ${url} (HTTP ${HTTP_STATUS})"
        echo ""
        log SUCCESS "Jenkins healthcheck passed."
        exit 0
    else 
        log ERROR "Jenkins is not responding at ${url}"
        echo ""
        log ERROR "Jenkins healthcheck failed."
        exit 1
    fi
}

# perform healthcheck
log INFO "starting Jenkins healthcheck ..."

check_jenkins "${JENKINS_URL}"