#!/bin/bash

set -euo pipefail

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# auto-load .env if exists (in script's directory)
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    source "${SCRIPT_DIR}/.env"
fi

# Configuration
# work also with localhost, correct address specified in Jenkinsfile
FASTAPI_URL="${1:-http://localhost:8000/health}"
# not implemented yet, but placeholder for future use
FASTAPI_TOKEN="${FASTAPI_TOKEN:-}"
# do nothing if using HTTP (it could be false or true), works only for HTTPS
# insecure mode
FASTAPI_SKIP_SSL_VERIFY="${FASTAPI_SKIP_SSL_VERIFY:-false}" 
VERBOSE="${VERBOSE:-false}"

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
    if [[ "${FASTAPI_SKIP_SSL_VERIFY}" == "true" ]]; then
        log WARN "INSECURE MODE ENABLED - SSL certificate verification disabled!"
        log WARN "This should NEVER be used in production environments!"
    fi
    # not implemented yet
    if [[ -n "${FASTAPI_TOKEN}" ]]; then
        log INFO "Using Bearer token authentication"
    fi
    
    if [[ "${VERBOSE}" == "true" ]]; then
        log INFO "Verbose mode enabled - showing full curl output"
    fi
}

# Healthcheck function
check_fastapi() {
    local url="$1"
    
    log INFO "Checking FastAPI health at ${url}..."
    
    # Build curl options
    local curl_opts="-s --max-time 5 -w %{http_code} -o /dev/null"
    
    # Add Bearer token if provided
    # not implemented yet
    if [[ -n "${FASTAPI_TOKEN}" ]]; then
        curl_opts="${curl_opts} -H \"Authorization: Bearer ${FASTAPI_TOKEN}\""
    fi
    
    # Add insecure flag if requested
    if [[ "${FASTAPI_SKIP_SSL_VERIFY}" == "true" ]]; then
        curl_opts="${curl_opts} -k"
    fi
    
    # Add verbose flag if requested
    if [[ "${VERBOSE}" == "true" ]]; then
        curl_opts="${curl_opts} -v"
    fi
    
    # Retry loop with exponential backoff
    for i in $(seq 1 ${MAX_RETRIES}); do
        echo ""
        log INFO "ATTEMPT ${i}/${MAX_RETRIES}"
        
        # Calculate exponential backoff: 2^(i-1) * RETRY_DELAY
        local delay=$((RETRY_DELAY * (2 ** (i - 1))))
        
        # Execute curl with error handling
        set +e
        HTTP_STATUS=$(eval curl ${curl_opts} "${url}")
        CURL_EXIT_CODE=$?
        set -e
        
        # Network-level check (liveness)
        if [[ "${CURL_EXIT_CODE}" -ne 0 ]]; then
            log ERROR "Failed to connect to ${url} (curl exit code: ${CURL_EXIT_CODE})"
            
            # Common curl error codes
            case ${CURL_EXIT_CODE} in
                6)  log ERROR "Could not resolve host" ;;
                7)  log ERROR "Failed to connect to host" ;;
                28) log ERROR "Connection timeout" ;;
                35) log ERROR "SSL connection error" ;;
                60) log ERROR "SSL certificate problem (try FASTAPI_SKIP_SSL_VERIFY=true for dev)" ;;
            esac
            
            if [[ ${i} -lt ${MAX_RETRIES} ]]; then
                log INFO "Retrying in ${delay} seconds..."
                sleep ${delay}
            fi
            continue
        fi
        
        # HTTP-level check (readiness)
        if [[ "${HTTP_STATUS}" -eq 200 ]]; then
            log SUCCESS "FastAPI is healthy and reachable at ${url} (HTTP ${HTTP_STATUS})"
            echo ""
            log SUCCESS "FastAPI healthcheck PASSED"
            exit 0
        elif [[ "${HTTP_STATUS}" -eq 401 ]] || [[ "${HTTP_STATUS}" -eq 403 ]]; then
            log ERROR "Authentication failed at ${url} (HTTP ${HTTP_STATUS})"
            log ERROR "Check FASTAPI_TOKEN if authentication is required"
            # Don't retry auth failures
            exit 1 
        elif [[ "${HTTP_STATUS}" -eq 503 ]]; then
            log ERROR "Service unavailable at ${url} (HTTP ${HTTP_STATUS})"
            
            if [[ ${i} -lt ${MAX_RETRIES} ]]; then
                log INFO "Service may be starting up, retrying in ${delay} seconds..."
                sleep ${delay}
            fi
        else
            log ERROR "FastAPI unhealthy at ${url} (HTTP ${HTTP_STATUS})"
            
            if [[ ${i} -lt ${MAX_RETRIES} ]]; then
                log INFO "Retrying in ${delay} seconds..."
                sleep ${delay}
            fi
        fi
    done
    
    echo ""
    log ERROR "FastAPI healthcheck FAILED after ${MAX_RETRIES} attempts"
    exit 1
}

# Main execution
log INFO "=== Starting FastAPI Healthcheck ==="
check_security_config
check_fastapi "${FASTAPI_URL}"