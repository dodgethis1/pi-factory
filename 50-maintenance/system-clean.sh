#!/usr/bin/env bash
set -uo pipefail

# 50-maintenance/system-clean.sh
# Cleans a Raspberry Pi system to prepare for creating a "Golden Image" or to free up space.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SYSTEM CLEANUP TOOL ===${NC}"
echo "This script will perform several cleanup tasks to reduce disk usage and improve privacy."
echo "It is ideal before creating a 'Golden Image' or for general maintenance."
read -rp "Press Enter to continue or Ctrl+C to abort..."

FREE_SPACE_BEFORE=$(df -h / | awk 'NR==2 {print $4}')
echo -e "\n${YELLOW}--- Disk usage before cleanup: $FREE_SPACE_BEFORE free ---${NC}"

# --- 1. Clean APT cache ---
echo -e "\n${YELLOW}--- 1/4: Cleaning APT cache ---${NC}"
sudo apt-get clean
sudo apt-get -y autoremove --purge
echo -e "${GREEN}APT cache cleaned.${NC}"

# --- 2. Clear old logs ---
echo -e "\n${YELLOW}--- 2/4: Clearing old system logs ---${NC}"
sudo journalctl --vacuum-size=50M # Keep logs under 50MB
sudo find /var/log -type f -regex ".*\.gz$\|.*\.log\.[0-9]$" -delete
echo -e "${GREEN}Old logs cleared.${NC}"

# --- 3. Clear temporary files ---
echo -e "\n${YELLOW}--- 3/4: Clearing temporary files ---${NC}"
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
echo -e "${GREEN}Temporary files cleared.${NC}"

# --- 4. Clear user history and caches (optional, but good for golden images) ---
echo -e "\n${YELLOW}--- 4/4: Clearing user history and caches ---${NC}"
# Clear current user's bash history
history -c && history -w
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        echo "  - Clearing history for $(basename "$user_home")..."
        sudo rm -f "$user_home/.bash_history"
        sudo rm -rf "$user_home/.cache"
    fi
done
echo "  - Clearing root's bash history..."
sudo rm -f /root/.bash_history
echo -e "${GREEN}User history and caches cleared.${NC}"

FREE_SPACE_AFTER=$(df -h / | awk 'NR==2 {print $4}')
echo -e "\n${YELLOW}--- Disk usage after cleanup: $FREE_SPACE_AFTER free ---${NC}"

echo -e "\n${BLUE}=== SYSTEM CLEANUP COMPLETE ===${NC}"
echo "Consider running 'sudo sync' and then rebooting for full effect."
echo -e "\n${BLUE}===============================${NC}"
