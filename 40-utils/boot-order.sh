#!/usr/bin/env bash
set -euo pipefail

# 40-utils/boot-order.sh
# Configure the Raspberry Pi 5 Boot Order (EEPROM).

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== BOOT ORDER CONFIGURATION ===${NC}"
echo "Configure which device the Raspberry Pi tries to boot from first."
echo "Current Boot Order:"
rpi-eeprom-config | grep BOOT_ORDER || echo "Unknown"
echo

echo "Select Boot Priority:"
echo "1) SD Card Priority (Default)  [SD -> NVMe -> USB]"
echo "2) NVMe Priority               [NVMe -> SD -> USB]"
echo "3) USB Priority                [USB -> NVMe -> SD]"
echo "0) Cancel"

read -rp "Select option: " CHOICE

# Helper to apply config
apply_boot_order() {
    local ORDER="$1"
    echo -e "\n${YELLOW}Applying BOOT_ORDER=$ORDER...${NC}"
    
    # Create temp config
    TEMP_CONF=$(mktemp)
    rpi-eeprom-config --config "$TEMP_CONF" > /dev/null
    
    # Update BOOT_ORDER in temp config
    if grep -q "BOOT_ORDER=" "$TEMP_CONF"; then
        sed -i "s/^BOOT_ORDER=.*/BOOT_ORDER=$ORDER/" "$TEMP_CONF"
    else
        echo "BOOT_ORDER=$ORDER" >> "$TEMP_CONF"
    fi
    
    # Apply
    sudo rpi-eeprom-config --apply "$TEMP_CONF"
    rm "$TEMP_CONF"
    
    echo -e "${GREEN}Boot order updated. Reboot to take effect.${NC}"
}

# Boot Codes (Read Right-to-Left)
# 1 = SD Card
# 4 = USB Mass Storage
# 6 = NVMe
# f = Restart

case "$CHOICE" in
    1)
        # Try SD(1), then NVMe(6), then USB(4), then Restart(f)
        # Order: 0xf461
        apply_boot_order "0xf461"
        ;;
    2)
        # Try NVMe(6), then SD(1), then USB(4), then Restart(f)
        # Order: 0xf416
        apply_boot_order "0xf416"
        ;;
    3)
        # Try USB(4), then NVMe(6), then SD(1), then Restart(f)
        # Order: 0xf164
        apply_boot_order "0xf164"
        ;;
    0)
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac
