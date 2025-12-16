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

    # Boot Media Detection
    ROOT_DEV=$(findmnt / -o SOURCE -n)
    if [[ "$ROOT_DEV" == *mmcblk* ]]; then
        BOOT_MEDIA="SD Card"
        MODE_STATUS="${GREEN}PROVISIONING MODE (Safe to Flash)${NC}"
    elif [[ "$ROOT_DEV" == *nvme* ]]; then
        BOOT_MEDIA="NVMe SSD"
        MODE_STATUS="${RED}LIVE SYSTEM MODE (Do Not Flash)${NC}"
    elif [[ "$ROOT_DEV" == *sd* ]]; then
        BOOT_MEDIA="USB/SATA"
        MODE_STATUS="${GREEN}PROVISIONING MODE (Safe to Flash)${NC}"
    else
        BOOT_MEDIA="Unknown ($ROOT_DEV)"
        MODE_STATUS="${YELLOW}UNKNOWN MODE${NC}"
    fi
}

# Helper: Banner
show_header() {
    get_sys_info
    clear
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BOLD}   PI-FACTORY ${GREEN}v2.5${NC} (${YELLOW}${GIT_VER}${NC})   |   Golden Key Provisioning   ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo -e " User: ${CYAN}$TARGET_USER${NC}  |  Host: ${CYAN}$TARGET_HOSTNAME${NC}  |  IP: ${CYAN}$MY_IP${NC}"
    echo -e " Zone: ${CYAN}$TARGET_TIMEZONE${NC}  |  Temp: ${YELLOW}$CPU_TEMP${NC}   |  Boot: ${YELLOW}$BOOT_MEDIA${NC}"
    echo -e " Mode: ${BOLD}$MODE_STATUS${NC}"
    echo -e "${BLUE}----------------------------------------------------------------${NC}"
}

# Main Menu
main_menu() {
    load_config
    while true; do
        show_header
        
        echo -e "${RED}${BOLD} [ PROVISIONING ]${NC}"
        echo -e "  1) ${RED}Flash NVMe Drive${NC}     [Run from SD/USB] (Wipe & Install OS)"
        echo -e "  2) ${YELLOW}Seed NVMe (Offline)${NC}   [Run from SD/USB] (Configure target NVMe)"
        echo
        
        echo -e "${BLUE}${BOLD} [ CONFIGURATION ]${NC}"
        echo -e "  3) Configure Live System [Run from NVMe]   (User, Wifi, SSH, GitHub Keys)"
        echo -e "  4) Security Wizard       (SSH Keys, Firewall, Hardening)"
        echo -e "  5) Install Apps          (Pi-Apps, RPi Connect)"
        echo -e "  6) Install Cases         (Pironman, Argon)"
        echo -e "  7) Install Extras        (Docker, Tailscale, Cockpit)"
        echo
        
        echo -e "${GREEN}${BOLD} [ DIAGNOSTICS ]${NC}"
        echo -e "  8) System Dashboard      (Health, Power, Storage, Net)"
        echo -e "  9) Disk Benchmark        (FIO - 4K Random R/W)"
        echo -e " 10) Network Benchmark     (Internet & Local Speed)"
        echo -e " 11) NVMe Speed Test       (Sequential Read - Raw)"
        echo
        
        echo -e "${YELLOW}${BOLD} [ HARDWARE TUNING ]${NC}"
        echo -e " 12) Set PCIe Speed       [Pi 5 Only] (Gen 1 / Gen 2 / Gen 3)"
        echo -e " 13) Pi Overclocking      (CPU Frequency & Voltage)"
        echo -e " 14) Apply NVMe Fixes     (Kernel Stability)"
        echo -e " 15) Update Bootloader    (EEPROM Firmware)"
        echo
        
        echo -e "${CYAN}${BOLD} [ MAINTENANCE ]${NC}"
        echo -e " 16) System Updates       (OS Upgrade & Firmware)"
        echo -e " 17) System Cleanup       (Free up disk space)"
        echo -e " 18) Backup Drive         [Run from SD/USB] (Create compressed image)"
        echo -e " 19) Clone Toolkit        (Backup to USB/SD)"
        echo -e " 20) Update Toolkit       (Pull from GitHub)"
        echo
        
        echo -e "${BOLD} [ POWER ]${NC}"
        echo -e " 21) Reboot / Shutdown"
        echo -e "  0) Exit"
        echo
        read -rp "Select an option: " choice

        case "$choice" in
            1)
                # Extra Safety Check
                if [[ "$BOOT_MEDIA" == "NVMe SSD" ]]; then
                    echo -e "${RED}ERROR: You are currently booted from NVMe.${NC}"
                    echo "You cannot flash the drive you are running on."
                    echo "Please boot from the Golden SD Card to use this function."
                    read -rp "Press Enter to continue..."
                else
                    bash "$BASE_DIR/10-flash/flash-nvme.sh"
                fi
                ;;
            2)
                bash "$BASE_DIR/20-configure/seed-offline.sh"
                ;;
            3)
                bash "$BASE_DIR/20-configure/configure-live.sh"
                ;;
            4)
                bash "$BASE_DIR/20-configure/security-wizard.sh"
                ;;
            5)
                bash "$BASE_DIR/30-software/install-apps.sh"
                ;;
            6)
                bash "$BASE_DIR/30-software/install-cases.sh"
                ;;
            7)
                bash "$BASE_DIR/30-software/install-extras.sh"
                ;;
            8)
                bash "$BASE_DIR/99-diagnostics/dashboard.sh"
                ;;
            9)
                bash "$BASE_DIR/99-diagnostics/bench-disk.sh"
                ;;
            10)
                bash "$BASE_DIR/99-diagnostics/bench-net.sh"
                ;;
            11)
                bash "$BASE_DIR/99-diagnostics/nvme-test.sh"
                ;;
            12)
                bash "$BASE_DIR/40-utils/set-pcie-speed.sh"
                ;;
            13)
                bash "$BASE_DIR/40-utils/pi-overclock.sh"
                ;;
            14)
                bash "$BASE_DIR/40-utils/apply-kernel-fixes.sh"
                ;;
            15)
                bash "$BASE_DIR/40-utils/update-bootloader.sh"
                ;;
            16)
                echo "Running System Updates..."
                sudo apt-get update && sudo apt-get full-upgrade -y
                echo "Cleaning up..."
                sudo apt-get autoremove -y
                echo "Update Complete."
                ;;
            17)
                bash "$BASE_DIR/50-maintenance/system-clean.sh"
                ;;
            18)
                bash "$BASE_DIR/50-maintenance/backup-drive.sh"
                ;;
            19)
                bash "$BASE_DIR/40-utils/clone-toolkit.sh"
                ;;
            20)
                echo "Updating Toolkit..."
                git -C "$BASE_DIR" pull || echo "Update failed."
                sleep 2
                ;;
            21)
                echo "1) Reboot"
                echo "2) Shutdown (Power Off)"
                read -rp "Select: " pwr
                if [[ "$pwr" == "1" ]]; then sudo reboot; fi
                if [[ "$pwr" == "2" ]]; then sudo poweroff; fi
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