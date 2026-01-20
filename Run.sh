#!/usr/bin/env bash
set -e

# ================================
# Configuration
# ================================
VM_NAME="windows-server-2025"
DISK_SIZE="120G"

DATA_DIR="$(pwd)/data"
ISO_DIR="$DATA_DIR/iso"
DISK_DIR="$DATA_DIR/disk"

WIN_ISO="windows-server-2025.iso"
VIRTIO_ISO="virtio-win.iso"

WIN_ISO_URL="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
VIRTIO_ISO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso"

DISK_IMAGE="$DISK_DIR/${VM_NAME}.qcow2"

# ================================
# Prepare directories
# ================================
mkdir -p "$ISO_DIR" "$DISK_DIR"

# ================================
# Download ISOs if missing
# ================================
[ ! -f "$ISO_DIR/$WIN_ISO" ] && curl -L "$WIN_ISO_URL" -o "$ISO_DIR/$WIN_ISO"
[ ! -f "$ISO_DIR/$VIRTIO_ISO" ] && curl -L "$VIRTIO_ISO_URL" -o "$ISO_DIR/$VIRTIO_ISO"

# ================================
# Create disk if missing
# ================================
if [ ! -f "$DISK_IMAGE" ]; then
  qemu-img create -f qcow2 "$DISK_IMAGE" "$DISK_SIZE"
fi

# ================================
# Run Windows VM in Docker
# ================================
docker run -it --rm \
  --name "$VM_NAME" \
  --device /dev/kvm \
  -p 3389:3389 \
  -v "$ISO_DIR:/isos" \
  -v "$DISK_DIR:/disk" \
  qemu/qemu:latest \
  qemu-system-x86_64 \
    -enable-kvm \
    -m 8G \
    -cpu host \
    -smp 4 \
    -machine q35 \
    -drive file=/disk/${VM_NAME}.qcow2,format=qcow2,if=virtio \
    -cdrom /isos/$WIN_ISO \
    -drive file=/isos/$VIRTIO_ISO,media=cdrom \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389 \
    -device virtio-net-pci,netdev=net0 \
    -vga qxl \
    -boot order=d
