#!/usr/bin/env bash
set -euo pipefail

# 40-utils/pi-fan-control.sh
# Configure the Raspberry Pi 5 Active Cooler fan curve.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="/boot/firmware/config.txt"

echo -e "${BLUE}=== PI 5 FAN CONTROL ===${NC}"
echo "Configure the Active Cooler fan behavior."
echo "Current Temp: $(vcgencmd measure_temp)"
echo

echo "Select Fan Profile:"
echo "1) Standard (Default) - Balanced cooling"
echo "2) Aggressive (Cool)  - Fans spin up earlier (Good for NVMe)"
echo "3) Silent Mode        - Higher temps allowed before fans spin"
echo "4) Full Speed Test    - Run fan at 100% for 10 seconds"
echo "0) Cancel"

read -rp "Select option: " CHOICE

# Function to clear existing fan settings
clear_fan_settings() {
    sudo sed -i '/^dtparam=fan_temp/d' "$CONFIG_FILE"
}

case "$CHOICE" in
    1)
        echo "Applying Standard Profile..."
        clear_fan_settings
        # No settings needed, default is standard
        echo -e "${GREEN}Standard profile applied.${NC}"
        ;;
    2)
        echo "Applying Aggressive Profile..."
        clear_fan_settings
        # Turn on earlier: 50C=75 speed, 60C=125 speed, 67C=175 speed, 75C=255(Max)
        echo "dtparam=fan_temp0=50000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp0_hyst=2000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp0_speed=75" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp1=60000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp1_speed=125" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp2=67000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp2_speed=175" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp3=75000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp3_speed=255" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo -e "${GREEN}Aggressive profile applied.${NC}"
        ;;
    3)
        echo "Applying Silent Profile..."
        clear_fan_settings
        # Start late: 60C start, Max only at 80C
        echo "dtparam=fan_temp0=60000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp0_speed=75" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp3=80000" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo "dtparam=fan_temp3_speed=255" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo -e "${GREEN}Silent profile applied.${NC}"
        ;;
    4)
        echo "Running Fan Test..."
        # Create a temporary override
        echo "255" | sudo tee /sys/class/thermal/cooling_device0/cur_state > /dev/null
        echo "Fan set to MAX. Listen..."
        sleep 10
        # Reset to auto (usually 0 allows kernel control again, or it resets on temp change)
        echo "0" | sudo tee /sys/class/thermal/cooling_device0/cur_state > /dev/null
        echo "Test complete."
        exit 0
        ;;
    0)
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

if [[ "$CHOICE" != "4" ]]; then
    echo -e "${YELLOW}A REBOOT is required for fan profiles to take effect.${NC}"
fi
