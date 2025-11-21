#!/bin/bash

# Animated start function
animate_menu() {
    echo -e "\e[1;34m"
    echo "======================================"
    echo "        WINDOWS 11 SETUP SCRIPT       "
    echo "             By ALLAY XD 20           "
    echo "======================================"
    for i in {1..3}; do
        echo -ne "Starting Windows 11 Setup"
        for j in {1..3}; do
            echo -n "."
            sleep 0.3
        done
        echo -ne "\r"
        echo -ne "                              \r"
    done
    echo -e "\e[0m"
}

while true; do
    clear
    echo -e "\e[1;34m"
    echo "======================================"
    echo "            WINDOWS 11 MENU           "
    echo "             By ALLAY XD 20           "
    echo "======================================"
    echo -e "\e[0m"
    echo "0. WINDOWS RDP SETUP"
    echo "1. LOCALHOST RDP (Tailscale true)"
    echo "2. NO VNC TO ACCESS"
    echo "3. EXIT"
    echo -n "Choose an option: "
    read option

    case $option in
        0)
            animate_menu
            read -p "Do you want to use Tailscale for remote access? (y/n) " tailscale_ans
            read -p "Enter custom RDP port (e.g., 3390): " RDPPORT

            sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager curl

            mkdir -p ~/vms/windows11
            WINISO=~/vms/windows11/Win11_24H2_English_x64.iso
            if [ ! -f "$WINISO" ]; then
                echo "Downloading Windows 11 ISO..."
                wget -O $WINISO https://archive.org/download/windows-11-24h2-iso_202501/Win11_24H2_English_x64.iso
            fi

            DISKSIZE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
            MEM=$(free -m | awk '/Mem:/ {printf "%d", $2*0.9}')
            CPU=$(nproc --all)

            virt-install --name windows11 --ram $MEM --vcpus $CPU --os-variant win11 \
                --cdrom "$WINISO" --disk path=~/vms/windows11/windows11.qcow2,size=$DISKSIZE \
                --graphics spice,listen=0.0.0.0,port=5900 --video qxl --boot uefi \
                --network network=default --noautoconsole

            echo "Waiting for VM network to start..."
            sleep 15

            VM_IP=""
            for i in {1..10}; do
                VM_IP=$(virsh domifaddr windows11 | awk '/ipv4/ {print $4}' | cut -d/ -f1)
                if [ -n "$VM_IP" ]; then break; fi
                echo "Detecting VM IP... retry $i/10"
                sleep 3
            done

            if [ -z "$VM_IP" ]; then
                echo "Could not detect VM IP. Check manually."
            else
                echo "Detected Windows VM IP: $VM_IP"
                sudo iptables -t nat -A PREROUTING -p tcp --dport $RDPPORT -j DNAT --to-destination $VM_IP:3389
                sudo iptables -t nat -A POSTROUTING -j MASQUERADE
                echo "RDP available at localhost:$RDPPORT → Windows 11 VM ($VM_IP:3389)"
            fi

            if [[ "$tailscale_ans" == "y" || "$tailscale_ans" == "yes" ]]; then
                curl -fsSL https://tailscale.com/install.sh | sh
                sudo tailscale up
            fi

            read -p "Setup complete! Press Enter to return to menu..."
            ;;

        1)
            echo "Setting up localhost RDP with Tailscale..."
            read -p "Enter custom RDP port (e.g., 3390): " RDPPORT

            VM_IP=$(virsh domifaddr windows11 | awk '/ipv4/ {print $4}' | cut -d/ -f1)
            if [ -z "$VM_IP" ]; then
                echo "No running Windows VM detected. Please run option 0 first."
                read -p "Press Enter to return to menu..."
                continue
            fi

            echo "Detected Windows VM IP: $VM_IP"
            sudo iptables -t nat -A PREROUTING -p tcp --dport $RDPPORT -j DNAT --to-destination $VM_IP:3389
            sudo iptables -t nat -A POSTROUTING -j MASQUERADE

            if ! command -v tailscale &> /dev/null; then
                curl -fsSL https://tailscale.com/install.sh | sh
            fi
            sudo tailscale up

            echo "RDP available at localhost:$RDPPORT → Windows 11 VM ($VM_IP:3389) via Tailscale"
            read -p "Press Enter to return to menu..."
            ;;

        2)
            echo "Setting up VM with NO VNC/SPICE access..."
            VM_EXIST=$(virsh list --name | grep windows11)
            if [ -n "$VM_EXIST" ]; then
                echo "Shutting down existing VM..."
                virsh shutdown windows11
                sleep 5
                virsh undefine windows11 --remove-all-storage
            fi

            read -p "Enter custom RDP port (e.g., 3390): " RDPPORT

            mkdir -p ~/vms/windows11
            WINISO=~/vms/windows11/Win11_24H2_English_x64.iso
            if [ ! -f "$WINISO" ]; then
                wget -O $WINISO https://archive.org/download/windows-11-24h2-iso_202501/Win11_24H2_English_x64.iso
            fi

            DISKSIZE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
            MEM=$(free -m | awk '/Mem:/ {printf "%d", $2*0.9}')
            CPU=$(nproc --all)

            virt-install --name windows11 --ram $MEM --vcpus $CPU --os-variant win11 \
                --cdrom "$WINISO" --disk path=~/vms/windows11/windows11.qcow2,size=$DISKSIZE \
                --graphics none --boot uefi --network network=default --noautoconsole

            echo "Waiting 15 seconds for VM network..."
            sleep 15

            VM_IP=""
            for i in {1..10}; do
                VM_IP=$(virsh domifaddr windows11 | awk '/ipv4/ {print $4}' | cut -d/ -f1)
                if [ -n "$VM_IP" ]; then break; fi
                echo "Detecting VM IP... retry $i/10"
                sleep 3
            done

            if [ -n "$VM_IP" ]; then
                sudo iptables -t nat -A PREROUTING -p tcp --dport $RDPPORT -j DNAT --to-destination $VM_IP:3389
                sudo iptables -t nat -A POSTROUTING -j MASQUERADE
                echo "RDP only setup complete at localhost:$RDPPORT → Windows 11 VM ($VM_IP:3389)"
            else
                echo "Could not detect VM IP."
            fi

            read -p "Press Enter to return to menu..."
            ;;

        3)
            echo "Exiting..."
            exit 0
            ;;

        *)
            echo "Invalid option, try again."
            sleep 1
            ;;
    esac
done
