#!/usr/bin/env bash
set -euo pipefail

# Run an HP-UX VM under QEMU. You MUST provide an HP-UX disk image or ISO.
# Usage:
#   ./scripts/run-hpux.sh -i /path/to/hpux.img -a hppa|ia64 [-m 2048] [-n name]
# Notes:
# - Emulation of HP-UX depends on QEMU support on your host. This script tries qemu-system-hppa and qemu-system-ia64.
# - You are responsible for obtaining HP-UX installation media and license.

IMAGE=""
ARCH="hppa"
MEM=1024
NAME="hpux-vm"

while getopts "i:a:m:n:h" opt; do
  case "$opt" in
    i) IMAGE="$OPTARG" ;;
    a) ARCH="$OPTARG" ;;
    m) MEM="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    *) echo "Usage: $0 -i /path/to/image [-a hppa|ia64] [-m MB] [-n name]"; exit 1 ;;
  esac
done

if [ -z "$IMAGE" ]; then
  echo "Error: no image provided. Use -i /path/to/hpux.img or .iso"
  exit 2
fi

# Find qemu binary
QEMU_CMD=""
if [ "$ARCH" = "hppa" ]; then
  if command -v qemu-system-hppa >/dev/null 2>&1; then QEMU_CMD="qemu-system-hppa"; fi
elif [ "$ARCH" = "ia64" ] || [ "$ARCH" = "ia64" ]; then
  if command -v qemu-system-ia64 >/dev/null 2>&1; then QEMU_CMD="qemu-system-ia64"; fi
fi

if [ -z "$QEMU_CMD" ]; then
  echo "qemu-system for architecture '$ARCH' not found. Install QEMU with the appropriate targets."
  echo "Available qemu binaries: " $(which qemu-system-x86_64 qemu-system-ia64 qemu-system-hppa 2>/dev/null || true)
  exit 3
fi

# Normal run: attach image as virtio/ide depending on arch
echo "Starting HP-UX VM: $NAME using $QEMU_CMD with image $IMAGE"

# Choose machine options conservatively
if [ "$ARCH" = "hppa" ]; then
  # hppa emulation has limited device support
  exec "$QEMU_CMD" -m "$MEM" -drive file="$IMAGE",if=ide,format=raw -nographic -serial mon:stdio
else
  # ia64/Itanium support in QEMU may be limited; try a graphical session if available
  exec "$QEMU_CMD" -m "$MEM" -drive file="$IMAGE",if=ide,format=raw -vga std
fi
