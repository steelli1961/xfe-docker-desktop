#!/usr/bin/env bash
set -euo pipefail

# Attempt to build and run CDE inside a Docker container and forward X11 from host.
# This is a best-effort automation: building CDE requires source and dependencies.
# Usage:
#  ./scripts/run-cde.sh [--repo <git_repo_url>] [--tag <branch-or-tag>] [--image <image_name>] [--display <DISPLAY>]

REPO="https://github.com/ibara/cde.git"
TAG="main"
IMAGE_NAME="cde-builder:latest"
DISPLAY_ENV=${DISPLAY:-":0"}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --tag) TAG="$2"; shift 2 ;;
    --image) IMAGE_NAME="$2"; shift 2 ;;
    --display) DISPLAY_ENV="$2"; shift 2 ;;
    --help|-h) echo "Usage: $0 [--repo <git_repo>] [--tag <branch>] [--image <name>] [--display <DISPLAY>]"; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Create a temporary build context
CTX_DIR=".cde-docker-build"
mkdir -p "$CTX_DIR"
cat > "$CTX_DIR/Dockerfile" <<'DOCK'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git automake autoconf libtool pkg-config cmake \
    xorg x11-xserver-utils xauth xinit openmotif libx11-dev libxmu-dev libxaw7-dev libice-dev libsm-dev libxt-dev libxext-dev libfontconfig1-dev libfreetype6-dev libxfixes-dev libssl-dev curl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /src
DOCK

echo "Building Docker image $IMAGE_NAME (this may take time)..."
docker build -t "$IMAGE_NAME" "$CTX_DIR"

echo "Starting container to clone/build/run CDE. If build fails you'll be dropped into a shell to debug."

# Run container, mount X11 socket, pass DISPLAY and allow host Xauthority
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
touch "$XAUTH"

# ensure Xauthority exists and allow local connections (user's responsibility)
xauth_list=$(xauth nlist "$DISPLAY_ENV" 2>/dev/null || true)
if [ -n "$xauth_list" ]; then
  echo "$xauth_list" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge - || true
fi

# Run builder container; clone repo and attempt build. If fail, open shell.
docker run --rm -it \
  -e DISPLAY="$DISPLAY_ENV" \
  -v "$XSOCK":"$XSOCK" \
  -v "$XAUTH":"/tmp/.docker.xauth" \
  -e XAUTHORITY="/tmp/.docker.xauth" \
  --device /dev/dri \
  --name cde-builder-run \
  "$IMAGE_NAME" bash -lc "set -e; git clone --depth 1 --branch '${TAG}' '${REPO}' src || git clone '${REPO}' src || true; cd src || (echo 'Repo not found in container'; bash); if [ -f autogen.sh ]; then ./autogen.sh || true; fi; if [ -f configure ]; then ./configure --prefix=/usr || true; fi; if make -j\$(nproc); then echo 'Build succeeded'; else echo 'Build failed — dropping to shell'; bash; fi; if command -v startcde >/dev/null 2>&1; then echo 'Launching CDE'; startcde & sleep 99999; else echo 'startcde not found — drop to shell'; bash; fi"

# cleanup
rm -rf "$CTX_DIR"

echo "Done. If CDE didn't start, run the container again or inspect logs."
