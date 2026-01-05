#!/bin/bash

set -euo pipefail

URL="${1:-http://localhost:8000/health}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
}

log "INFO" "starting FastAPI healthcheck for ${URL} ..."

HTTP_STATUS=$(curl -f -s --max-time 5 -w "%{http_code}" -o /dev/null "${URL}") || CURL_EXIT_CODE=$?
CURL_EXIT_CODE=${CURL_EXIT_CODE:-0}

if [ "${CURL_EXIT_CODE}" -ne 0 ]; then
    log "ERROR" "healthcheck failed to connect to ${URL} (curl exit code: ${CURL_EXIT_CODE})"
    exit 1
fi

if [ "${HTTP_STATUS}" -eq 200 ]; then
    log "SUCCESS" "healthy and reachable at ${URL} (HTTP ${HTTP_STATUS})"
    exit 0
else
    log "ERROR" "unhealthy at ${URL} (HTTP ${HTTP_STATUS})"
    exit 1
fi
