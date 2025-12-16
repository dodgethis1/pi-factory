#!/usr/bin/env bash
set -uo pipefail

# 40-utils/update-bootloader.sh
# Checks for and updates the Raspberry Pi 5 bootloader (EEPROM).

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== RASPBERRY PI BOOTLOADER UPDATE TOOL ===${NC}"
echo "This tool checks for available EEPROM updates and applies them."
echo "Updating the bootloader can improve stability and compatibility (e.g., with NVMe)."
read -rp "Press Enter to continue or Ctrl+C to abort..."

# 1. Dependency Check
echo -e "\n${YELLOW}--- 1/2: Checking rpi-eeprom ---${NC}"
if ! command -v rpi-eeprom-update &>/dev/null; then
    echo "rpi-eeprom package not found. Installing..."
    sudo apt-get update && sudo apt-get install -y rpi-eeprom
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to install rpi-eeprom. Aborting.${NC}"
        exit 1
    fi
    echo "rpi-eeprom installed."
else
    echo "rpi-eeprom is already installed."
fi

# 2. Check for Updates
echo -e "\n${YELLOW}--- 2/2: Checking for available updates ---${NC}"
CURRENT_EEPROM=$(rpi-eeprom-update | grep "CURRENT:" | awk '{print $2}')
LATEST_EEPROM=$(rpi-eeprom-update | grep "LATEST:" | awk '{print $2}')

echo "Current EEPROM version: $CURRENT_EEPROM"
echo "Latest EEPROM version:  $LATEST_EEPROM"

if [[ "$CURRENT_EEPROM" == "$LATEST_EEPROM" ]]; then
    echo -e "${GREEN}Your EEPROM is already up to date!${NC}"
else
    echo -e "${YELLOW}An EEPROM update is available.${NC}"
    read -rp "Do you want to apply the update? (y/N): " APPLY_UPDATE

    if [[ "$APPLY_UPDATE" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Applying EEPROM update... This will take a moment.${NC}"
        # This command updates the /lib/firmware/raspberrypi/bootloader/stable symlink
        # and configures the system to update on next reboot.
        sudo rpi-eeprom-update -a
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: Failed to apply EEPROM update.${NC}"
            exit 1
        fi
        echo -e "${GREEN}EEPROM update staged. A REBOOT IS REQUIRED for changes to take effect.${NC}"
    else
        echo -e "${YELLOW}EEPROM update skipped.${NC}"
    fi
fi

echo -e "\n${BLUE}===========================================${NC}"
