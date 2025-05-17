#!/bin/bash

check_redis_health() {
    if [[ -n "${REDIS_PASSWORD}" ]]; then
        export REDISCLI_AUTH="${REDIS_PASSWORD}"
    fi
    if [[ "${TLS_MODE}" == "true" ]]; then
        redis-cli --tls --cert "${REDIS_TLS_CERT}" --key "${REDIS_TLS_CERT_KEY}" --cacert "${REDIS_TLS_CA_KEY}" -h "$(hostname)" -p "${SENTINEL_PORT}" ping

    elif ip addr show net1 &>/dev/null; then
        # Use Multus IP as bind address for Redis
        redis-cli -h "$(ip -4 addr show net1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')" -p "${SENTINEL_PORT}" ping

    else
        redis-cli -h "localhost" -p "${SENTINEL_PORT}" ping
    fi
}

check_redis_health
