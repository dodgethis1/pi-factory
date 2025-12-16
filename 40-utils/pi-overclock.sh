#!/usr/bin/env bash
set -uo pipefail

# 40-utils/pi-overclock.sh
# Menu-driven tool to apply overclock profiles for Raspberry Pi 5.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_DIR="/boot/firmware/config_backups"

echo -e "${BLUE}=== RASPBERRY PI OVERCLOCKING TOOL ===${NC}"
echo "WARNING: Overclocking can lead to instability, data corruption, and potentially reduce the lifespan of your Pi."
echo "         Ensure adequate cooling for your Raspberry Pi 5 (active cooler recommended)."
read -rp "Press Enter to continue or Ctrl+C to abort..."

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Backup current config.txt
echo -e "\n${YELLOW}Backing up current config.txt to $BACKUP_DIR...${NC}"
cp "$CONFIG_FILE" "$BACKUP_DIR/config.txt.bak.$(date +%Y%m%d-%H%M%S)"

# Define overclock profiles
declare -A PROFILES
PROFILES["0"]="Default (1.5GHz) - No Overclock"
PROFILES["1"]="Mild (2.6GHz) - Safe, slight boost"
PROFILES["2"]="Performance (2.8GHz) - Good balance"
PROFILES["3"]="Aggressive (3.0GHz) - Requires excellent cooling, may be unstable"
PROFILES["4"]="Custom - Manually enter frequency"

select_profile() {
    echo -e "\n${YELLOW}--- Select Overclock Profile ---${NC}"
    for i in "${!PROFILES[@]}"; do
        echo "$i) ${PROFILES[$i]}"
    done
    echo -e "q) Quit${NC}"

    read -rp "Enter choice: " CHOICE

    case "$CHOICE" in
        0)  echo "Applying Default settings..."
            sudo sed -i '/^arm_freq=/d' "$CONFIG_FILE"
            sudo sed -i '/^over_voltage=/d' "$CONFIG_FILE"
            ;; 
        1)  echo "Applying Mild (2.6GHz) settings..."
            sudo sed -i '/^arm_freq=/d' "$CONFIG_FILE"
            sudo sed -i '/^over_voltage=/d' "$CONFIG_FILE"
            echo "arm_freq=2600" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "over_voltage=6" | sudo tee -a "$CONFIG_FILE" > /dev/null
            ;; 
        2)  echo "Applying Performance (2.8GHz) settings..."
            sudo sed -i '/^arm_freq=/d' "$CONFIG_FILE"
            sudo sed -i '/^over_voltage=/d' "$CONFIG_FILE"
            echo "arm_freq=2800" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "over_voltage=8" | sudo tee -a "$CONFIG_FILE" > /dev/null
            ;; 
        3)  echo "Applying Aggressive (3.0GHz) settings..."
            sudo sed -i '/^arm_freq=/d' "$CONFIG_FILE"
            sudo sed -i '/^over_voltage=/d' "$CONFIG_FILE"
            echo "arm_freq=3000" | sudo tee -a "$CONFIG_FILE" > /dev/null
            echo "over_voltage=10" | sudo tee -a "$CONFIG_FILE" > /dev/null
            ;; 
        4)  read -rp "Enter custom arm_freq (e.g., 2700): " CUSTOM_FREQ
            read -rp "Enter custom over_voltage (e.g., 7): " CUSTOM_VOLT
            if [[ -n "$CUSTOM_FREQ" && -n "$CUSTOM_VOLT" ]]; then
                echo "Applying Custom settings: arm_freq=$CUSTOM_FREQ, over_voltage=$CUSTOM_VOLT"
                sudo sed -i '/^arm_freq=/d' "$CONFIG_FILE"
                sudo sed -i '/^over_voltage=/d' "$CONFIG_FILE"
                echo "arm_freq=$CUSTOM_FREQ" | sudo tee -a "$CONFIG_FILE" > /dev/null
                echo "over_voltage=$CUSTOM_VOLT" | sudo tee -a "$CONFIG_FILE" > /dev/null
            else
                echo -e "${RED}Invalid custom values. Aborting custom setting.${NC}"
            fi
            ;; 
        q|Q) echo -e "${YELLOW}Exiting overclocking tool. No changes applied.${NC}"
            exit 0
            ;; 
        *)  echo -e "${RED}Invalid choice. Please try again.${NC}"
            select_profile
            ;; 
    esac
}

select_profile

echo -e "\n${GREEN}--- OVERCLOCK SETTINGS APPLIED ---${NC}"
echo "Current config.txt (relevant lines):"
grep -E '^(arm_freq|over_voltage)=' "$CONFIG_FILE" || echo "No overclock settings found."
echo "A REBOOT IS REQUIRED for changes to take effect."

echo -e "\n${BLUE}=======================================${NC}"
