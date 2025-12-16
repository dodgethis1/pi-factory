#!/usr/bin/env bash
set -euo pipefail

# Pi-Factory Main Entry Point
# This script guides you through the provisioning process.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper: Load Config
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo -e "${RED}ERROR: Configuration file missing: $CONFIG_FILE${NC}"
        echo "Please copy config/settings.conf.example to config/settings.conf"
        exit 1
    fi
}

# Helper: Banner
show_header() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}   PI-FACTORY v2.0   |   Golden Key Provisioning Tool     ${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo "User: $TARGET_USER  |  Host: $TARGET_HOSTNAME  |  Zone: $TARGET_TIMEZONE"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

# Main Menu
main_menu() {
    load_config
    while true; do
        show_header
        echo "1) [DESTRUCTIVE] Flash NVMe Drive (Wipe & Install OS)"
        echo "2) Seed NVMe (Create User, Wifi, SSH Keys - FROM SD)"
        echo "3) Configure Live System (User, Wifi, SSH - ON NVMe)"
        echo "4) Install Software (Pi-Apps, RPi Connect, Repo)"
        echo "5) Install Case Software (Pironman, Argon)"
        echo "6) Install Extras (Docker, Tailscale, Cockpit)"
        echo "7) System Updates (OS Upgrade & Firmware)"
        echo "8) Power Options (Reboot, Shutdown)"
        echo "9) Clone Toolkit (Copy to USB/SD)"
        echo "10) Apply NVMe Kernel Fixes (Stability)"
        echo "11) Force PCIe Gen 1 (Max Stability - Slower)"
        echo "99) Run NVMe Diagnostics (Speed & Health Check)"
        echo "0) Exit"
        echo
        read -rp "Select an option: " choice

        case "$choice" in
            1)
                bash "$BASE_DIR/10-flash/flash-nvme.sh"
                ;;
            2)
                bash "$BASE_DIR/20-configure/seed-offline.sh"
                ;;
            3)
                bash "$BASE_DIR/20-configure/configure-live.sh"
                ;;
            4)
                bash "$BASE_DIR/30-software/install-apps.sh"
                ;;
            5)
                bash "$BASE_DIR/30-software/install-cases.sh"
                ;;
            6)
                bash "$BASE_DIR/30-software/install-extras.sh"
                ;;
            7)
                echo "Running System Updates..."
                apt-get update && apt-get full-upgrade -y
                echo "Cleaning up..."
                apt-get autoremove -y
                echo "Update Complete."
                ;;
            8)
                echo "1) Reboot"
                echo "2) Shutdown (Power Off)"
                read -rp "Select: " pwr
                if [[ "$pwr" == "1" ]]; then reboot; fi
                if [[ "$pwr" == "2" ]]; then poweroff; fi
                ;;
            9)
                bash "$BASE_DIR/40-utils/clone-toolkit.sh"
                ;;
            10)
                bash "$BASE_DIR/40-utils/apply-kernel-fixes.sh"
                ;;
            11)
                bash "$BASE_DIR/40-utils/force-pcie-gen1.sh"
                ;;
            99)
                bash "$BASE_DIR/99-diagnostics/nvme-test.sh"
                ;;
            0)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
        
        echo
        read -rp "Press Enter to return to menu..." _
    done
}

# Check for root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root. Try: sudo ./main.sh${NC}"
   exit 1
fi

main_menu
