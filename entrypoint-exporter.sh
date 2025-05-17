#!/bin/bash
REDIS_PORT="6379"

if ip addr show net1 &>/dev/null; then
  # Use Multus IP as bind address for Redis
  MULTUS_IP="$(ip -4 addr show net1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
  REDIS_ADDR="redis://${MULTUS_IP}:${REDIS_PORT}"

  # Redis Exporter
  /usr/local/bin/redis_exporter

else
  REDIS_ADDR="redis://localhost:${REDIS_PORT}"

  # Redis Exporter
  /usr/local/bin/redis_exporter
fi
