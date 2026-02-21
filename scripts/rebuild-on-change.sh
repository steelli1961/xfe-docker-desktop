#!/usr/bin/env bash
set -euo pipefail

# Usage:
#  ./scripts/rebuild-on-change.sh [-f] [-i image_name] [-t tag] [-d dockerfile] [context]
# Defaults:
#  image_name: xfe-kde-variant
#  tag: latest
#  dockerfile: dockerfile-kde-variant
#  context: current directory

FORCE=0
IMAGE_NAME="xfe-kde-variant"
TAG="latest"
DOCKERFILE="dockerfile-kde-variant"
CONTEXT="."

while getopts "fi:t:d:c:" opt; do
  case "$opt" in
    f) FORCE=1 ;;
    i) IMAGE_NAME="$OPTARG" ;;
    t) TAG="$OPTARG" ;;
    d) DOCKERFILE="$OPTARG" ;;
    c) CONTEXT="$OPTARG" ;;
    *) echo "Usage: $0 [-f] [-i image_name] [-t tag] [-d dockerfile] [-c context]"; exit 1 ;;
  esac
done
shift $((OPTIND-1))

HASH_DIR=".build_hashes"
mkdir -p "$HASH_DIR"
HASH_FILE="$HASH_DIR/$(echo "$IMAGE_NAME" | tr '/:' '__')_${TAG}.sha256"

# choose hashing tool (sha256sum or shasum)
if command -v sha256sum >/dev/null 2>&1; then
  HASH_CMD="sha256sum"
  HASH_AWK='{print $1}'
else
  HASH_CMD="shasum -a 256"
  HASH_AWK='{print $1}'
fi

if [ ! -f "$DOCKERFILE" ]; then
  echo "Dockerfile not found at: $DOCKERFILE"
  exit 2
fi

CURRENT_HASH=$(eval "$HASH_CMD \"$DOCKERFILE\"" | awk "$HASH_AWK")
OLD_HASH=""
if [ -f "$HASH_FILE" ]; then
  OLD_HASH=$(cat "$HASH_FILE") || true
fi

if [ "$FORCE" -eq 1 ] || [ "$CURRENT_HASH" != "$OLD_HASH" ]; then
  echo "Change detected (or forced). Rebuilding image $IMAGE_NAME:$TAG..."

  # remove existing image if present
  EXISTING_ID=$(docker images -q "$IMAGE_NAME:$TAG" || true)
  if [ -n "$EXISTING_ID" ]; then
    echo "Removing existing image id: $EXISTING_ID"
    docker rmi -f "$EXISTING_ID" || true
  fi

  # build new image
  docker build -t "$IMAGE_NAME:$TAG" -f "$DOCKERFILE" "$CONTEXT"

  # save new hash on success
  echo "$CURRENT_HASH" > "$HASH_FILE"
  echo "Build complete and hash updated at $HASH_FILE"
else
  echo "No changes detected for $DOCKERFILE; skipping rebuild."
fi
