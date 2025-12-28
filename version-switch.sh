#!/usr/bin/env bash
set -euo pipefail

#######################################
# Target files
#######################################
FILES=$(ls Dockerfile* 2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "Dockerfile* not found"
  exit 1
fi

#######################################
# Current REDIS versions
#######################################
echo "# Current REDIS versions:"
echo "- File Name"

CURRENT_LINES=$(grep -HnE 'ARG[[:space:]]+REDIS_(SENTINEL_)?VERSION' $FILES || true)

if [ -z "$CURRENT_LINES" ]; then
  echo "No REDIS_VERSION found"
else
  echo "$CURRENT_LINES" \
    | sed -E 's|^([^:]+):([0-9]+):ARG[[:space:]]+([^=]+)=(.*)|\1, \2 Line, \3=\4|'
fi

echo
#######################################
# Fetch Redis official releases
#######################################
echo "Fetching Redis official releases..."
echo "(source: https://download.redis.io/releases/)"
echo

REDIS_VERSIONS=""

if command -v curl >/dev/null 2>&1; then
  REDIS_VERSIONS=$(curl -s https://download.redis.io/releases/ \
    | grep -oE 'redis-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' \
    | sed 's/redis-//;s/.tar.gz//' \
    | sort -V \
    | uniq \
    | tail -n 20)

  echo "$REDIS_VERSIONS"
else
  echo "curl not found – skip version list"
fi

echo
#######################################
# User input (safe with set -u)
#######################################
NEW_REDIS_VERSION=""
NEW_REDIS_SENTINEL_VERSION=""

read -r -p "Enter new REDIS_VERSION: " NEW_REDIS_VERSION || true
read -r -p "Enter new REDIS_SENTINEL_VERSION: " NEW_REDIS_SENTINEL_VERSION || true

if [ -z "$NEW_REDIS_VERSION" ]; then
  echo "REDIS_VERSION is empty"
  exit 1
fi

if [ -z "$NEW_REDIS_SENTINEL_VERSION" ]; then
  echo "REDIS_SENTINEL_VERSION is empty"
  exit 1
fi

#######################################
# sed -i compatibility (GNU / BSD)
#######################################
SED_INPLACE=(-i)
if ! sed --version >/dev/null 2>&1; then
  SED_INPLACE=(-i '')
fi

#######################################
# Apply version changes
#######################################
for f in $FILES; do
  sed "${SED_INPLACE[@]}" \
    -E "s|^(ARG[[:space:]]+REDIS_VERSION=).*|\1\"${NEW_REDIS_VERSION}\"|" \
    "$f"

  sed "${SED_INPLACE[@]}" \
    -E "s|^(ARG[[:space:]]+REDIS_SENTINEL_VERSION=).*|\1\"${NEW_REDIS_SENTINEL_VERSION}\"|" \
    "$f"
done

#######################################
# Verify result
#######################################
echo
echo "# Updated REDIS versions:"
echo "- File Name"

grep -HnE 'ARG[[:space:]]+REDIS_(SENTINEL_)?VERSION' $FILES \
  | sed -E 's|^([^:]+):([0-9]+):ARG[[:space:]]+([^=]+)=(.*)|\1, \2 Line, \3=\4|'
