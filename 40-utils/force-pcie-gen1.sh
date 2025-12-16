#!/usr/bin/env bash
set -euo pipefail

# 40-utils/force-pcie-gen1.sh
# Forces PCIe link speed to Gen 1 for maximum stability.

CONFIG_FILE="/boot/firmware/config.txt"
BACKUP_FILE="${CONFIG_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
TARGET_PARAM="dtparam=pciex1_gen=1"

echo "=== FORCE PCIe GEN 1 ==="

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: config.txt not found at $CONFIG_FILE."
    echo "This script is meant for Raspberry Pi OS."
    exit 1
fi

echo "Backing up original config.txt to $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

CURRENT_CONFIG=$(cat "$CONFIG_FILE")
UPDATED_CONFIG="$CURRENT_CONFIG"

if ! echo "$UPDATED_CONFIG" | grep -q "\b$TARGET_PARAM\b"; then
    echo "Adding: $TARGET_PARAM to config.txt"
    echo "" >> "$CONFIG_FILE" # Ensure a newline before appending
    echo "$TARGET_PARAM" >> "$CONFIG_FILE"
    echo "Changes applied. A reboot is required for them to take effect."
else
    echo "$TARGET_PARAM already present. No changes needed."
fi

echo "=== FORCE PCIe GEN 1 COMPLETE ==="
echo "Please REBOOT your Raspberry Pi for the changes to take effect."
