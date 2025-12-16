#!/usr/bin/env bash
set -euo pipefail

# 40-utils/clone-toolkit.sh
# Clones the Pi-Factory toolkit to another drive (USB/SD)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

echo -e "${BLUE}=== CLONE TOOLKIT ===${NC}"
echo "This tool copies the Pi-Factory toolkit to another drive."
echo "Useful for creating a new 'Golden USB' or backing up to SD."
echo
echo "Available Devices:"
lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE,MOUNTPOINT | grep -v "loop"
echo

read -rp "Enter target device name (e.g., sda or mmcblk0): " DEV_NAME

if [[ -z "$DEV_NAME" ]]; then
    echo "No device selected."
    exit 1
fi

# Construct full path
TARGET_DEV="/dev/$DEV_NAME"
if [[ ! -b "$TARGET_DEV" ]]; then
    echo -e "${RED}ERROR: Device $TARGET_DEV not found.${NC}"
    exit 1
fi

# Determine partitions
if [[ "$DEV_NAME" == mmcblk* || "$DEV_NAME" == nvme* ]]; then
    PART1="/dev/${DEV_NAME}p1"
    PART2="/dev/${DEV_NAME}p2"
else
    PART1="/dev/${DEV_NAME}1"
    PART2="/dev/${DEV_NAME}2"
fi

# --- SAFETY CHECK ---
MODEL=$(lsblk -no MODEL "$TARGET_DEV" | head -n1)
SIZE=$(lsblk -no SIZE "$TARGET_DEV" | head -n1)

echo -e "\n${YELLOW}Target Confirmation:${NC}"
echo "   Device: $TARGET_DEV"
echo "   Model:  $MODEL"
echo "   Size:   $SIZE"
echo
echo "We will mount Partition 2 ($PART2) and copy the toolkit there."
read -rp "Is this correct? (y/N): " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then echo "Aborted."; exit 0; fi

echo "Checking partition $PART2..."
if [[ ! -b "$PART2" ]]; then
    echo -e "${RED}ERROR: Partition $PART2 not found.${NC}"
    echo "The target drive must be formatted with a standard partition layout."
    exit 1
fi

MOUNT_POINT="/mnt/clone-target"
mkdir -p "$MOUNT_POINT"

echo "Mounting $PART2 to $MOUNT_POINT..."
mount "$PART2" "$MOUNT_POINT"

# Determine install path
TARGET_DIR="$MOUNT_POINT/opt/pi-factory"
if [[ -d "$MOUNT_POINT/home" ]]; then
    # It looks like a Linux OS drive (has /home)
    TARGET_DIR="$MOUNT_POINT/opt/pi-factory"
    echo "Detected Linux OS. Installing to /opt/pi-factory."
else
    # It might be a plain data USB
    TARGET_DIR="$MOUNT_POINT/pi-factory"
    echo "Detected Data Drive. Installing to root/pi-factory."
fi

echo "Copying toolkit..."
mkdir -p "$TARGET_DIR"
rsync -ax --exclude '.git' --info=progress2 "$BASE_DIR/" "$TARGET_DIR/"

echo "Installing shortcut..."
SHORTCUT="$MOUNT_POINT/usr/local/bin/pi-factory"
mkdir -p "$MOUNT_POINT/usr/local/bin"
echo "#!/bin/bash" > "$SHORTCUT"
echo "cd $TARGET_DIR" >> "$SHORTCUT"
echo "sudo bash main.sh" >> "$SHORTCUT"
chmod +x "$SHORTCUT"

echo "Syncing..."
sync
umount "$MOUNT_POINT"

echo -e "\n${GREEN}Clone Complete!${NC}"