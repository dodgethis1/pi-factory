#!/usr/bin/env bash
set -euo pipefail

# Pi-Factory Main Entry Point
# This script guides you through the provisioning process.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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

# Helper: Get System Info
get_sys_info() {
    # Version
    GIT_VER=$(git -C "$BASE_DIR" describe --tags --always --dirty 2>/dev/null || echo "Unknown")
    
    # IP
    MY_IP=$(hostname -I | awk '{print $1}')
    [[ -z "$MY_IP" ]] && MY_IP="No Network"

    # Temp
    if [[ -f /sys/class/thermal/thermal_zone0/temp ]]; then
        CPU_TEMP=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
    else
        CPU_TEMP="N/A"
    fi
}

# Helper: Banner
show_header() {
    get_sys_info
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BOLD}   PI-FACTORY ${GREEN}v2.1${NC} (${YELLOW}${GIT_VER}${NC})   |   Golden Key Provisioning   ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e " User: ${CYAN}$TARGET_USER${NC}  |  Host: ${CYAN}$TARGET_HOSTNAME${NC}  |  IP: ${CYAN}$MY_IP${NC}"
    echo -e " Zone: ${CYAN}$TARGET_TIMEZONE${NC}  |  Temp: ${YELLOW}$CPU_TEMP${NC}"
    echo -e "${BLUE}----------------------------------------------------------------${NC}"
}

# Main Menu
main_menu() {
    load_config
    while true; do
        show_header
        
        echo -e "${RED}${BOLD} [ PROVISIONING ]${NC}"
        echo -e "  1) ${RED}Flash NVMe Drive${NC}     (Wipe & Install OS)"
        echo -e "  2) ${YELLOW}Seed NVMe (Offline)${NC}   (Configure from SD card)"
        echo
        
        echo -e "${BLUE}${BOLD} [ CONFIGURATION ]${NC}"
        echo -e "  3) Configure Live System (User, Wifi, SSH, GitHub Keys)"
        echo -e "  9) Clone Toolkit         (Backup to USB/SD)"
        echo
        
        echo -e "${GREEN}${BOLD} [ SOFTWARE ]${NC}"
        echo -e "  4) Install Apps          (Pi-Apps, RPi Connect)"
        echo -e "  5) Install Cases         (Pironman, Argon)"
        echo -e "  6) Install Extras        (Docker, Tailscale, Cockpit)"
        echo
        
        echo -e "${CYAN}${BOLD} [ MAINTENANCE ]${NC}"
        echo -e "  7) System Updates        (OS Upgrade & Firmware)"
        echo -e "  10) Apply NVMe Fixes     (Kernel Stability)"
        echo -e "  11) Force PCIe Gen 1     (Hardware Debugging)"
        echo -e "  12) Update Toolkit       (Pull from GitHub)"
        echo -e "  99) Run Diagnostics      (Speed & Health Check)"
        echo
        
        echo -e "  8) ${BOLD}Power Options${NC}        (Reboot/Shutdown)"
        echo -e "  0) Exit"
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
            12)
                echo "Updating Toolkit..."
                git -C "$BASE_DIR" pull || echo "Update failed."
                sleep 2
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
