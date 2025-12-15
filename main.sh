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
        echo "2) Configure System (User, Network, SSH, Security)"
        echo "3) Install Software (Pi-Apps, RPi Connect, Repo)"
        echo "4) Install Case Software (Pironman, Argon)"
        echo "5) Install Extras (Docker, Tailscale, Cockpit)"
        echo "6) Update Toolkit (Pull latest from GitHub)"
        echo "0) Exit"
        echo
        read -rp "Select an option: " choice

        case "$choice" in
            1)
                bash "$BASE_DIR/10-flash/flash-nvme.sh"
                ;;
            2)
                bash "$BASE_DIR/20-configure/configure-system.sh"
                ;;
            3)
                bash "$BASE_DIR/30-software/install-apps.sh"
                ;;
            4)
                bash "$BASE_DIR/30-software/install-cases.sh"
                ;;
            5)
                bash "$BASE_DIR/30-software/install-extras.sh"
                ;;
            6)
                echo "Updating..."
                git pull || echo "Update failed (not a git repo?)"
                sleep 2
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
