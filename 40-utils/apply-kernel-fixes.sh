#!/usr/bin/env bash
set -euo pipefail

# 40-utils/apply-kernel-fixes.sh
# Applies recommended kernel parameters for NVMe stability on Raspberry Pi 5.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

CMDLINE_FILE="/boot/firmware/cmdline.txt"
BACKUP_FILE="${CMDLINE_FILE}.bak.$(date +%Y%m%d-%H%M%S)"

NVME_FIXES=(
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    "pcie_port_pm=off"
)

echo "=== APPLY NVMe KERNEL FIXES ==="

if [[ ! -f "$CMDLINE_FILE" ]]; then
    echo "ERROR: cmdline.txt not found at $CMDLINE_FILE."
    echo "This script is meant for Raspberry Pi OS."
    exit 1
fi

echo "Backing up original cmdline.txt to $BACKUP_FILE"
cp "$CMDLINE_FILE" "$BACKUP_FILE"

CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")
UPDATED_CMDLINE="$CURRENT_CMDLINE"

for fix in "${NVME_FIXES[@]}"; do
    if ! echo "$UPDATED_CMDLINE" | grep -q "\b$fix\b"; then
        echo "Adding: $fix"
        UPDATED_CMDLINE="$UPDATED_CMDLINE $fix"
    else
        echo "Already present: $fix"
    fi
done

if [[ "$CURRENT_CMDLINE" != "$UPDATED_CMDLINE" ]]; then
    echo "Writing updated cmdline.txt"
    echo "$UPDATED_CMDLINE" > "$CMDLINE_FILE"
    echo "Changes applied. A reboot is required for them to take effect."
else
    echo "No changes needed. All fixes already present."
fi

echo "=== KERNEL FIXES COMPLETE ==="
echo "Please REBOOT your Raspberry Pi for the changes to take effect."
