#!/usr/bin/env bash
set -e

# ================================
# FIXED USER CONFIG (NO CHANGE)
# ================================
WIN_USER="docker"
WIN_PASS="Docker@2025!"

# ================================
# ASK USER FOR RESOURCES
# ================================
read -p "Enter CPU cores (example: 8): " CPU_CORES
read -p "Enter RAM size (example: 24g): " RAM_SIZE
read -p "Enter Disk size (example: 120G): " DISK_SIZE

read -p "Enter RDP port (example: 3389): " rdp_port
read -p "Enter Web port (example: 8080): " web_port

# ================================
# BASIC VALIDATION
# ================================
if [[ -z "$rdp_port" || -z "$web_port" ]]; then
  echo "ERROR: RDP port and Web port must not be empty"
  exit 1
fi

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
# PREPARE STORAGE
# ================================
mkdir -p "$DATA_DIR"

# ================================
# PERFORMANCE TUNING
# ================================
export DOCKER_BUILDKIT=1

# ================================
# REMOVE OLD CONTAINER
# ================================
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

# ================================
# RUN WINDOWS CONTAINER
# ================================
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --device /dev/kvm \
  --cap-add NET_ADMIN \
  --security-opt seccomp=unconfined \
  --memory "$RAM_SIZE" \
  --cpus "$CPU_CORES" \
  -p "$rdp_port:$rdp_port" \
  -p "$web_port:$web_port" \
  -v "$DATA_DIR:/storage" \
  -e VERSION=2025 \
  -e DISK_SIZE="$DISK_SIZE" \
  -e USERNAME="$WIN_USER" \
  -e PASSWORD="$WIN_PASS" \
  -e AUTO_START=yes \
  -e SKIP_CHECKS=yes \
  -e ENABLE_KVM=yes \
  dockurr/windows
