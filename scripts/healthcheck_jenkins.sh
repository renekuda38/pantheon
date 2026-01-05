#!/bin/bash 

set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"

MAX_RETRIES=3
RETRY_DELAY=2

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

    for i in $(seq 1 $MAX_RETRIES); do

        echo "ATTEMPT ${i}/${MAX_RETRIES}:"

        # curl with timeout and fail on HTTP errors
        set +e
        HTTP_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null "${URL}") 
        CURL_EXIT_CODE=$?
        set -e

        # network check (liveness)
        if [ "${CURL_EXIT_CODE}" -ne 0 ]; then
            log ERROR "failed to connect to Jenkins at ${url}) (curl exit code: ${CURL_EXIT_CODE})"
            echo ""
            log ERROR "Jenkins healthcheck failed."
            sleep $RETRY_DELAY
            continue
        fi

        # http check (readiness)
        if [ "${HTTP_STATUS}" -eq 200 ]; then
            log SUCCESS "Jenkins is healthy and reachable at ${url} (HTTP ${HTTP_STATUS})"
            echo ""
            log SUCCESS "Jenkins healthcheck passed."
            exit 0
        else 
            log ERROR "Jenkins is not responding at ${url}"
            echo ""
            log ERROR "Jenkins healthcheck failed."
            sleep $RETRY_DELAY
        fi
    done

    exit 1
}

# perform healthcheck
log INFO "starting Jenkins healthcheck ..."

check_jenkins "${JENKINS_URL}"