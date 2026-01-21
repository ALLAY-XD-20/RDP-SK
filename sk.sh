#!/usr/bin/env bash
set -e

# ================================
# COLORS (BLUE + RED THEME)
# ================================
RED='\033[1;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RESET='\033[0m'
BOLD='\033[1m'

BASE_DIR="$HOME/vms"
IMAGE="dockurr/windows"

mkdir -p "$BASE_DIR"

# ================================
# ROOT CHECK
# ================================
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as root (sudo)${RESET}"
  exit 1
fi

# ================================
# AUTO INSTALL REQUIREMENTS
# ================================
echo -e "${CYAN}Checking system requirements...${RESET}"

apt update -y

for pkg in docker.io jq lsof curl; do
  if ! command -v ${pkg%%.*} >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing $pkg...${RESET}"
    apt install -y $pkg
  fi
done

systemctl enable --now docker

# ================================
# KVM CHECK
# ================================
if [ ! -e /dev/kvm ]; then
  echo -e "${RED}ERROR: KVM not available${RESET}"
  exit 1
fi

# ================================
# ASCII ART
# ================================
clear
echo -e "${BLUE}${BOLD}
██████╗ ██╗  ██╗██████╗  ██████╗ ██╗███████╗
╚════██╗╚██╗██╔╝██╔══██╗██╔═══██╗██║╚══███╔╝
 █████╔╝ ╚███╔╝ ██████╔╝██║   ██║██║  ███╔╝ 
 ╚═══██╗ ██╔██╗ ██╔══██╗██║   ██║██║ ███╔╝  
██████╔╝██╔╝ ██╗██████╔╝╚██████╔╝██║███████╗
╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝╚══════╝
${RED}              3  X  B  O  I  Z
${RESET}"

# ================================
# MENU
# ================================
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${BLUE}[1] Create & Start New VM${RESET}"
echo -e "${BLUE}[2] Stop & Delete VM${RESET}"
echo -e "${BLUE}[3] List All VMs${RESET}"
echo -e "${BLUE}[4] VM Info${RESET}"
echo -e "${RED} [5] Exit${RESET}"
echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
read -p "$(echo -e ${YELLOW}Select option ➜ ${RESET})" OPT

# ================================
# OPTION 1 - CREATE VM
# ================================
if [ "$OPT" = "1" ]; then
  read -p "VM ID (1,2,3..): " VM_ID
  VM_DIR="$BASE_DIR/vm$VM_ID"
  CONFIG="$VM_DIR/config.json"

  if [ -d "$VM_DIR" ]; then
    echo -e "${RED}VM already exists${RESET}"
    exit 1
  fi

  read -p "CPU cores: " CPU
  read -p "RAM (example 16g): " RAM
  read -p "Disk (example 100G): " DISK
  read -p "RDP Port: " RDP_PORT
  read -p "WEB Port: " WEB_PORT
  read -p "Windows Password: " WIN_PASS

  mkdir -p "$VM_DIR/data"

cat > "$CONFIG" <<EOF
{
  "id": "$VM_ID",
  "cpu": "$CPU",
  "ram": "$RAM",
  "disk": "$DISK",
  "rdp_port": "$RDP_PORT",
  "web_port": "$WEB_PORT",
  "password": "$WIN_PASS"
}
EOF

  docker run -d \
    --name "vm$VM_ID" \
    --restart unless-stopped \
    --device /dev/kvm \
    --cap-add NET_ADMIN \
    --security-opt seccomp=unconfined \
    --memory "$RAM" \
    --cpus "$CPU" \
    -p "$RDP_PORT:3389" \
    -p "$WEB_PORT:8006" \
    -v "$VM_DIR/data:/storage" \
    -e VERSION=2025 \
    -e DISK_SIZE="$DISK" \
    -e USERNAME="docker" \
    -e PASSWORD="$WIN_PASS" \
    -e AUTO_START=yes \
    -e ENABLE_KVM=yes \
    $IMAGE

  echo -e "${BLUE}[✓] VM $VM_ID Started${RESET}"
fi

# ================================
# OPTION 2 - DELETE VM
# ================================
if [ "$OPT" = "2" ]; then
  read -p "VM ID: " VM_ID
  VM_DIR="$BASE_DIR/vm$VM_ID"

  docker rm -f "vm$VM_ID" 2>/dev/null || true
  read -p "Delete data folder? (y/n): " DEL
  [ "$DEL" = "y" ] && rm -rf "$VM_DIR"

  echo -e "${RED}[✓] VM $VM_ID Deleted${RESET}"
fi

# ================================
# OPTION 3 - LIST VMS
# ================================
if [ "$OPT" = "3" ]; then
  echo -e "${CYAN}Existing VMs:${RESET}"
  ls "$BASE_DIR" | sed 's/vm//'
fi

# ================================
# OPTION 4 - VM INFO
# ================================
if [ "$OPT" = "4" ]; then
  read -p "VM ID: " VM_ID
  CONFIG="$BASE_DIR/vm$VM_ID/config.json"

  if [ ! -f "$CONFIG" ]; then
    echo -e "${RED}VM not found${RESET}"
    exit 1
  fi

  echo -e "${BLUE}CPU:${RESET} $(jq -r .cpu $CONFIG)"
  echo -e "${BLUE}RAM:${RESET} $(jq -r .ram $CONFIG)"
  echo -e "${BLUE}Disk:${RESET} $(jq -r .disk $CONFIG)"
  echo -e "${BLUE}RDP Port:${RESET} $(jq -r .rdp_port $CONFIG)"
  echo -e "${BLUE}WEB Port:${RESET} $(jq -r .web_port $CONFIG)"
  echo -e "${BLUE}Password:${RESET} $(jq -r .password $CONFIG)"
fi

# ================================
# OPTION 5 - EXIT
# ================================
if [ "$OPT" = "5" ]; then
  exit 0
fi
