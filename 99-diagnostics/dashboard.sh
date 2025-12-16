#!/usr/bin/env bash
set -uo pipefail

# 99-diagnostics/dashboard.sh
# Mission Control Dashboard for Raspberry Pi
# Displays real-time health, power, network, and storage status.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== PI DASHBOARD ===${NC}"

# --- 1. SYSTEM INFO ---
MODEL=$(cat /proc/device-tree/model 2>/dev/null || echo "Raspberry Pi")
KERNEL=$(uname -r)
UPTIME=$(uptime -p)

echo -e "\n${YELLOW}--- SYSTEM ---${NC}"
echo "Model:   $MODEL"
echo "Kernel:  $KERNEL"
echo "Uptime:  $UPTIME"

# --- 2. POWER & THERMAL ---
# Throttled Hex Codes
# 0x50000 = Throttling occurred + Under-voltage occurred (Past)
# 0x5     = Throttling now + Under-voltage now (Active)
# Bit 0: Under-voltage detected
# Bit 1: Arm frequency capped
# Bit 2: Currently throttled
# Bit 3: Soft temp limit active
# Bit 16: Under-voltage has occurred
# Bit 17: Arm frequency capping has occurred
# Bit 18: Throttling has occurred
# Bit 19: Soft temp limit has occurred

echo -e "\n${YELLOW}--- POWER & THERMALS ---${NC}"

TEMP=$(vcgencmd measure_temp | cut -d= -f2)
VOLTS=$(vcgencmd measure_volts core | cut -d= -f2)
CLOCK_ARM=$(vcgencmd measure_clock arm | cut -d= -f2 | awk '{print $1/1000000 " MHz"}')

# Colorize Temp
TEMP_VAL=$(echo "$TEMP" | grep -oE '[0-9.]+')
if (( $(echo "$TEMP_VAL > 80" | bc -l) )); then
    TEMP_DISP="${RED}$TEMP${NC}"
elif (( $(echo "$TEMP_VAL > 60" | bc -l) )); then
    TEMP_DISP="${YELLOW}$TEMP${NC}"
else
    TEMP_DISP="${GREEN}$TEMP${NC}"
fi

echo -e "CPU Temp:    $TEMP_DISP"
echo "Core Volt:   $VOLTS"
echo "Clock Speed: $CLOCK_ARM"

# Decode Throttling
THROTTLED_HEX=$(vcgencmd get_throttled | cut -d= -f2)
THROTTLED_VAL=$((THROTTLED_HEX))

if [ "$THROTTLED_VAL" -eq 0 ]; then
    echo -e "Power Status: ${GREEN}OK (No throttling/undervoltage)${NC}"
else
    echo -e "Power Status: ${RED}ISSUES DETECTED ($THROTTLED_HEX)${NC}"
    
    # Check Current Status
    [ $((THROTTLED_VAL & 0x1)) -ne 0 ] && echo -e "  - ${RED}CRITICAL: Under-voltage DETECTED NOW${NC}"
    [ $((THROTTLED_VAL & 0x2)) -ne 0 ] && echo -e "  - ${RED}CRITICAL: ARM Freq Capped NOW${NC}"
    [ $((THROTTLED_VAL & 0x4)) -ne 0 ] && echo -e "  - ${RED}CRITICAL: Throttled NOW${NC}"
    [ $((THROTTLED_VAL & 0x8)) -ne 0 ] && echo -e "  - ${RED}CRITICAL: Soft Temp Limit Reached NOW${NC}"

    # Check Past Status
    [ $((THROTTLED_VAL & 0x10000)) -ne 0 ] && echo -e "  - ${YELLOW}History: Under-voltage occurred${NC}"
    [ $((THROTTLED_VAL & 0x20000)) -ne 0 ] && echo -e "  - ${YELLOW}History: ARM Freq Capping occurred${NC}"
    [ $((THROTTLED_VAL & 0x40000)) -ne 0 ] && echo -e "  - ${YELLOW}History: Throttling occurred${NC}"
    [ $((THROTTLED_VAL & 0x80000)) -ne 0 ] && echo -e "  - ${YELLOW}History: Soft Temp Limit occurred${NC}"
fi

# --- 3. STORAGE ---
echo -e "\n${YELLOW}--- STORAGE ---${NC}"
df -h / | awk 'NR==2 {print "Root FS:     " $4 " free of " $2 " (" $5 " used)"}'

# Check NVMe Link (if applicable)
if lspci | grep -q "Non-Volatile memory"; then
    PCI_ADDR=$(lspci | grep -i nvme | cut -d' ' -f1)
    LNKSTA=$(lspci -vv -s "$PCI_ADDR" 2>/dev/null | grep "LnkSta:" | sed 's/^[ \t]*//')
    
    SPEED="Unknown"
    if echo "$LNKSTA" | grep -q "Speed 2.5GT/s"; then SPEED="Gen 1 (Slow)"; fi
    if echo "$LNKSTA" | grep -q "Speed 5GT/s"; then SPEED="Gen 2 (Standard)"; fi
    if echo "$LNKSTA" | grep -q "Speed 8GT/s"; then SPEED="${GREEN}Gen 3 (Fast)${NC}"; fi
    
    echo -e "NVMe Link:   $SPEED"
else
    echo "NVMe Link:   Not Detected"
fi

# --- 4. NETWORK ---
echo -e "\n${YELLOW}--- NETWORK ---${NC}"
IP_ADDR=$(hostname -I | awk '{print $1}')
echo "IP Address:  ${IP_ADDR:-Not Connected}"

if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
    echo -e "Internet:    ${GREEN}Connected${NC}"
else
    echo -e "Internet:    ${RED}Disconnected${NC}"
fi

echo -e "\n${BLUE}========================${NC}"
