#!/usr/bin/env bash
set -euo pipefail

# 40-utils/clone-toolkit.sh
# Clones the Pi-Factory toolkit to another drive (USB/SD)

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"

echo "=== CLONE TOOLKIT ==="
echo "This will copy the Pi-Factory toolkit to another drive."
echo "Useful for creating a new 'Golden USB' or backing up to SD."

# List block devices
lsblk -o NAME,MODEL,SIZE,TYPE,FSTYPE
echo
read -rp "Enter target device (e.g., sda or mmcblk0): " DEV_NAME

if [[ -z "$DEV_NAME" ]]; then
    echo "No device selected."
    exit 1
fi

# Construct full path (handle special cases like mmcblk0p1 vs sda1)
if [[ "$DEV_NAME" == mmcblk* || "$DEV_NAME" == nvme* ]]; then
    PART1="/dev/${DEV_NAME}p1"
    PART2="/dev/${DEV_NAME}p2"
else
    PART1="/dev/${DEV_NAME}1"
    PART2="/dev/${DEV_NAME}2"
fi

echo "Checking partitions on $DEV_NAME..."
if [[ ! -b "$PART2" ]]; then
    echo "ERROR: Partition $PART2 not found. Is the drive partitioned?"
    echo "This tool copies FILES, not disk images. The target must be formatted."
    exit 1
fi

MOUNT_POINT="/mnt/clone-target"
mkdir -p "$MOUNT_POINT"

echo "Mounting $PART2 to $MOUNT_POINT..."
mount "$PART2" "$MOUNT_POINT"

TARGET_DIR="$MOUNT_POINT/opt/pi-factory"
if [[ -d "$MOUNT_POINT/home/jr" ]]; then
    # If it looks like a Pi OS drive, put it in /opt/pi-factory
    TARGET_DIR="$MOUNT_POINT/opt/pi-factory"
else
    # If it's just a USB stick, put it in root
    TARGET_DIR="$MOUNT_POINT/pi-factory"
fi

echo "Copying toolkit to $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
rsync -ax --exclude '.git' "$BASE_DIR/" "$TARGET_DIR/"

echo "Installing shortcut on target..."
# Only useful if it's a Linux OS drive, but harmless on a USB stick
SHORTCUT="$MOUNT_POINT/usr/local/bin/pi-factory"
mkdir -p "$MOUNT_POINT/usr/local/bin"
echo "#!/bin/bash" > "$SHORTCUT"
echo "cd $TARGET_DIR" >> "$SHORTCUT" # This variable expands to the path we decided above
echo "sudo bash main.sh" >> "$SHORTCUT"
chmod +x "$SHORTCUT"

echo "Syncing..."
sync
umount "$MOUNT_POINT"

echo "Clone Complete!"
