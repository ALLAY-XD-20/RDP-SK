#!/usr/bin/env bash
set -e

# ================================
# USER CONFIG (EDIT THESE)
# ================================
WIN_USER="docker"
WIN_PASS="Docker@2025!"
DISK_SIZE="120G"

# ================================
# SYSTEM CONFIG
# ================================
CONTAINER_NAME="windows-server-2025"
DATA_DIR="$HOME/windows-data"

# ================================
# HARD REQUIREMENTS CHECK
# ================================
if [ ! -e /dev/kvm ]; then
  echo "ERROR: /dev/kvm not found (KVM required)"
  exit 1
fi

# ================================
# PREPARE STORAGE (PERSIST DOWNLOAD)
# ================================
mkdir -p "$DATA_DIR"

# ================================
# PERFORMANCE TUNING (SAFE)
# ================================
export DOCKER_BUILDKIT=1

# ================================
# REMOVE OLD CONTAINER (SAFE)
# ================================
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# ================================
# RUN WINDOWS (DETACHED / ALWAYS ON)
# ================================
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --device /dev/kvm \
  --cap-add NET_ADMIN \
  --security-opt seccomp=unconfined \
  --memory 24g \
  --cpus 8 \
  -p 3389:3389 \
  -p 8006:8006 \
  -v "$DATA_DIR:/storage" \
  -e VERSION=2025 \
  -e DISK_SIZE="$DISK_SIZE" \
  -e USERNAME="$WIN_USER" \
  -e PASSWORD="$WIN_PASS" \
  -e AUTO_START=yes \
  -e SKIP_CHECKS=yes \
  -e ENABLE_KVM=yes \
  dockurr/windows
