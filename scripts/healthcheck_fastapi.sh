#!/bin/bash

set -euo pipefail

URL="${1:-http://localhost:8000/health}"

MAX_RETRIES=3
RETRY_DELAY=2

log() {
    if [[ "${1}" == "ERROR" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}" >&2
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
    fi
}

check_fastapi() {
    local url=${1}

    log INFO "checking app health at ${url} ..."

    for i in $(seq 1 $MAX_RETRIES); do

        echo "ATTEMPT ${i}/${MAX_RETRIES}:"

        set +e
        HTTP_STATUS=$(curl -s --max-time 5 -w "%{http_code}" -o /dev/null "${url}") 
        CURL_EXIT_CODE=$?
        set -e

        # network check (liveness)
        if [ "${CURL_EXIT_CODE}" -ne 0 ]; then
            log "ERROR" "healthcheck failed to connect to ${url} (curl exit code: ${CURL_EXIT_CODE})"
            sleep $RETRY_DELAY
            continue
        fi

        # http check (readiness)
        if [ "${HTTP_STATUS}" -eq 200 ]; then
            log "SUCCESS" "healthy and reachable at ${url} (HTTP ${HTTP_STATUS})"
            exit 0
        else
            log "ERROR" "unhealthy at ${url} (HTTP ${HTTP_STATUS})"
            sleep $RETRY_DELAY
        fi
    done

    exit 1
}

check_fastapi "${URL}"

log "INFO" "starting FastAPI healthcheck for ${url} ..."