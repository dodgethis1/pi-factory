#!/usr/bin/env bash
set -uo pipefail

# 40-utils/set-pcie-speed.sh
# Sets the PCIe link speed for Raspberry Pi 5 (Gen 1, Gen 2, or Gen 3).

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}=== SET PCIe LINK SPEED ===${NC}"
echo "Configure the PCIe interface speed for the NVMe drive."
echo " - Gen 1: Maximum stability, lowest speed."
echo " - Gen 2: Standard Raspberry Pi 5 speed (Default)."
echo " - Gen 3: High performance, but officially unsupported. Requires good cable/drive."
read -rp "Press Enter to continue..."

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}ERROR: config.txt not found at $CONFIG_FILE.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Backing up config.txt...${NC}"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Function to clear existing PCIe settings
clear_pcie_settings() {
    sudo sed -i '/^dtparam=pciex1_gen=/d' "$CONFIG_FILE"
}

# Menu
echo -e "\nSelect PCIe Generation:"
echo "  1) Gen 1 (Slow, Stable)"
echo "  2) Gen 2 (Standard, Default)"
echo "  3) Gen 3 (Fast, Experimental)"
echo "  0) Cancel"
read -rp "Enter selection [1-3]: " CHOICE

case "$CHOICE" in
    1)
        echo "Setting PCIe to Gen 1..."
        clear_pcie_settings
        echo "dtparam=pciex1_gen=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo -e "${GREEN}Gen 1 enabled.${NC}"
        ;;
    2)
        echo "Setting PCIe to Gen 2..."
        clear_pcie_settings
        echo "dtparam=pciex1_gen=2" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo -e "${GREEN}Gen 2 enabled.${NC}"
        ;;
    3)
        echo "Setting PCIe to Gen 3..."
        clear_pcie_settings
        echo "dtparam=pciex1_gen=3" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo -e "${GREEN}Gen 3 enabled.${NC}"
        ;;
    0)
        echo "Cancelled."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid selection.${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}A REBOOT is required for changes to take effect.${NC}"
echo -e "${BLUE}=================================${NC}"
