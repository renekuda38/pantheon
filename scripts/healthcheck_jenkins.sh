#!/bin/bash

set -euo pipefail

  # Auto-load .env if exists
  if [[ -f .env ]]; then
      source .env
  fi

# Configuration
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_USER="${JENKINS_USER:-}"
JENKINS_TOKEN="${JENKINS_TOKEN:-}"
JENKINS_SKIP_SSL_VERIFY="${JENKINS_SKIP_SSL_VERIFY:-false}"

MAX_RETRIES=3
RETRY_DELAY=2  # Base delay in seconds

# Logging function
log() {
    if [[ "${1}" == "ERROR" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}" >&2
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${*:2}"
    fi
}

# Security warnings
check_security_config() {
    # HTTPS insecure mode warning
    if [[ "${JENKINS_SKIP_SSL_VERIFY}" == "true" ]]; then
        log WARN "INSECURE MODE ENABLED - SSL certificate verification disabled!"
        log WARN "This should NEVER be used in production environments!"
    fi
    
    if [[ -z "${JENKINS_USER}" ]] || [[ -z "${JENKINS_TOKEN}" ]]; then
        log WARN "Jenkins user or token not provided - authentication may fail"
        log WARN "Set JENKINS_USER and JENKINS_TOKEN environment variables"
    fi
}

# Healthcheck function
check_jenkins() {
    local url="$1"
    
    log INFO "Checking Jenkins health at ${url}..."
    
    # Build curl options
    local curl_opts="-s --max-time 5 -w %{http_code} -o /dev/null"
    
    # Add authentication if provided
    if [[ -n "${JENKINS_USER}" ]] && [[ -n "${JENKINS_TOKEN}" ]]; then
        curl_opts="${curl_opts} -u ${JENKINS_USER}:${JENKINS_TOKEN}"
        log INFO "Using Basic authentication (user: ${JENKINS_USER})"
    fi
    
    # Add insecure flag if requested
    if [[ "${JENKINS_SKIP_SSL_VERIFY}" == "true" ]]; then
        curl_opts="${curl_opts} -k"
    fi
    
    # Retry loop with exponential backoff
    for i in $(seq 1 ${MAX_RETRIES}); do
        echo ""
        log INFO "ATTEMPT ${i}/${MAX_RETRIES}"
        
        # Calculate delay: 2^(i-1) * RETRY_DELAY
        # Attempt 1: 2^0 * 2 = 2s
        # Attempt 2: 2^1 * 2 = 4s
        # Attempt 3: 2^2 * 2 = 8s
        local delay=$((RETRY_DELAY * (2 ** (i - 1))))
        
        # Execute curl with error handling
        set +e
        HTTP_STATUS=$(eval curl ${curl_opts} "${url}")
        CURL_EXIT_CODE=$?
        set -e
        
        # Network-level check (liveness)
        if [[ "${CURL_EXIT_CODE}" -ne 0 ]]; then
            log ERROR "Failed to connect to Jenkins at ${url} (curl exit code: ${CURL_EXIT_CODE})"
            
            if [[ ${i} -lt ${MAX_RETRIES} ]]; then
                log INFO "Retrying in ${delay} seconds..."
                sleep ${delay}
            fi
            continue
        fi
        
        # HTTP-level check (readiness)
        if [[ "${HTTP_STATUS}" -eq 200 ]]; then
            log SUCCESS "Jenkins is healthy and reachable at ${url} (HTTP ${HTTP_STATUS})"
            echo ""
            log SUCCESS "Jenkins healthcheck PASSED"
            exit 0
        elif [[ "${HTTP_STATUS}" -eq 403 ]] || [[ "${HTTP_STATUS}" -eq 401 ]]; then
            log ERROR "Authentication failed at ${url} (HTTP ${HTTP_STATUS})"
            log ERROR "Check JENKINS_USER and JENKINS_TOKEN credentials"
            exit 1  # Don't retry auth failures
        else
            log ERROR "Jenkins unhealthy at ${url} (HTTP ${HTTP_STATUS})"
            
            if [[ ${i} -lt ${MAX_RETRIES} ]]; then
                log INFO "Retrying in ${delay} seconds..."
                sleep ${delay}
            fi
        fi
    done
    
    echo ""
    log ERROR "Jenkins healthcheck FAILED after ${MAX_RETRIES} attempts"
    exit 1
}

# Main execution
log INFO "=== Starting Jenkins Healthcheck ==="
check_security_config
check_jenkins "${JENKINS_URL}"