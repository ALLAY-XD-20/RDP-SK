#!/bin/bash
set -e

# ============================================================
# Windows Server 2025 VM - Docker + KVM
# Host: Debian 11
# ============================================================

CONTAINER_NAME="windows-server-2025"

CPU_CORES="10"
RAM_SIZE="34G"
DISK_SIZE="164G"

WIN_USER="admin$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
WIN_PASS="Docker@2025!"

STORAGE="/opt/windows-server-2025"

echo "=================================================="
echo " Windows Server 2025 - Docker/KVM"
echo "=================================================="

# ------------------------------------------------------------
# Check KVM
# ------------------------------------------------------------

if [ ! -e /dev/kvm ]; then
    echo "[ERROR] /dev/kvm does not exist."
    echo "KVM virtualization is not available to this host."
    exit 1
fi

echo "[OK] KVM: /dev/kvm"

# ------------------------------------------------------------
# Check Docker
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is not installed."
    exit 1
fi

echo "[OK] Docker installed"

# ------------------------------------------------------------
# Host information
# ------------------------------------------------------------

HOST_IP=$(hostname -I | awk '{print $1}')

PUBLIC_IP=$(curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null || \
            echo "Unable to detect")

CPU_INFO=$(lscpu | grep "Model name" | sed 's/Model name:[[:space:]]*//')
HOST_CORES=$(nproc)

echo
echo "Host information"
echo "--------------------------------------------------"
echo "CPU       : $CPU_INFO"
echo "CPU cores : $HOST_CORES"
echo "Local IP  : $HOST_IP"
echo "Public IP : $PUBLIC_IP"
echo

# ------------------------------------------------------------
# VM configuration
# ------------------------------------------------------------

echo "VM configuration"
echo "--------------------------------------------------"
echo "VM name   : Windows Server 2025"
echo "Container : $CONTAINER_NAME"
echo "CPU       : $CPU_CORES vCPU"
echo "RAM       : $RAM_SIZE"
echo "Storage   : $DISK_SIZE"
echo "Username  : $WIN_USER"
echo "Password  : $WIN_PASS"
echo

# ------------------------------------------------------------
# Create storage
# ------------------------------------------------------------

mkdir -p "$STORAGE"

# ------------------------------------------------------------
# Remove old container if present
# ------------------------------------------------------------

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# ------------------------------------------------------------
# Start Windows Server 2025
# ------------------------------------------------------------

docker run -d \
    --name "$CONTAINER_NAME" \
    --device=/dev/kvm \
    --cap-add NET_ADMIN \
    -p 8006:8006 \
    -p 3389:3389 \
    -e VERSION=2025 \
    -e DISK_SIZE="$DISK_SIZE" \
    -e RAM_SIZE="$RAM_SIZE" \
    -e CPU_CORES="$CPU_CORES" \
    -e USERNAME="$WIN_USER" \
    -e PASSWORD="$WIN_PASS" \
    -e AUTO_START=yes \
    -e SKIP_CHECKS=yes \
    -e REGION=en-US \
    -e LANGUAGE=en-US \
    -e KEYBOARD=en-US \
    -e UNATTENDED=Y \
    -v "$STORAGE:/storage" \
    --restart unless-stopped \
    dockurr/windows

echo
echo "=================================================="
echo " Windows Server 2025 VM STARTED"
echo "=================================================="
echo
echo "Web console:"
echo "  http://$HOST_IP:8006"
echo
echo "RDP:"
echo "  $HOST_IP:3389"
echo
echo "Username:"
echo "  $WIN_USER"
echo
echo "Password:"
echo "  $WIN_PASS"
echo
echo "Public IP:"
echo "  $PUBLIC_IP"
echo
echo "Container:"
docker ps --filter "name=$CONTAINER_NAME"
echo
echo "Useful commands:"
echo "  docker logs -f $CONTAINER_NAME"
echo "  docker exec -it $CONTAINER_NAME bash"
echo "  docker restart $CONTAINER_NAME"
echo "  docker stop $CONTAINER_NAME"
echo
echo "Storage:"
echo "  $STORAGE"
echo
echo "=================================================="
