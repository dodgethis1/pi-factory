#!/usr/bin/env bash
set -uo pipefail

# 50-maintenance/backup-drive.sh
# Creates a compressed image of a specified drive or partition.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DRIVE BACKUP TOOL ===${NC}"
echo "WARNING: This tool creates a raw image of a drive."
echo "         DO NOT backup the drive you are currently booted from (e.g., /dev/nvme0n1 if you're running from NVMe)."
echo "         It is recommended to boot from an SD card to backup your NVMe drive, or vice-versa."
echo "         The target device will be UNMOUNTED during the process."
read -rp "Press Enter to continue or Ctrl+C to abort..."

echo -e "\n${YELLOW}--- 1. Select Source Drive ---${NC}"
lsblk -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT
echo ""
read -rp "Enter the SOURCE device to backup (e.g., nvme0n1, mmcblk0 - DO NOT include /dev/): " SOURCE_DEV_NAME

if [[ -z "$SOURCE_DEV_NAME" ]]; then
    echo -e "${RED}ERROR: No source device selected. Aborting.${NC}"
    exit 1
fi

SOURCE_DEV="/dev/$SOURCE_DEV_NAME"

if [[ ! -b "$SOURCE_DEV" ]]; then
    echo -e "${RED}ERROR: Source device $SOURCE_DEV not found or is not a block device. Aborting.${NC}"
    exit 1
fi

# Check if the source device is currently mounted
if mount | grep -q "$SOURCE_DEV"; then
    echo -e "${RED}WARNING: Source device $SOURCE_DEV is currently mounted.${NC}"
    read -rp "Attempt to unmount $SOURCE_DEV? (y/N): " UNMOUNT_CONFIRM
    if [[ "$UNMOUNT_CONFIRM" =~ ^[Yy]$ ]]; then
        sudo umount "$SOURCE_DEV"* # Unmount all partitions of the source
        if mount | grep -q "$SOURCE_DEV"; then
             echo -e "${RED}ERROR: Failed to unmount $SOURCE_DEV. Aborting. Please unmount manually.${NC}"
             exit 1
        else
            echo -e "${GREEN}Source device unmounted successfully.${NC}"
        fi
    else
        echo -e "${RED}Aborting. Please unmount $SOURCE_DEV manually before proceeding.${NC}"
        exit 1
    fi
fi

echo -e "\n${YELLOW}--- 2. Select Destination ---${NC}"
echo "Where should the backup image be saved?"
read -rp "Enter destination path (e.g., /mnt/usb_drive/backup.img.gz): " DEST_PATH

if [[ -z "$DEST_PATH" ]]; then
    echo -e "${RED}ERROR: No destination path provided. Aborting.${NC}"
    exit 1
fi

# Ensure parent directory exists
DEST_DIR=$(dirname "$DEST_PATH")
if [[ ! -d "$DEST_DIR" ]]; then
    echo -e "${YELLOW}Destination directory $DEST_DIR does not exist. Creating it...${NC}"
    sudo mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to create destination directory. Aborting.${NC}"
        exit 1
    fi
fi


echo -e "\n${YELLOW}--- 3. Starting Backup ---${NC}"
echo -e "Backing up ${BLUE}$SOURCE_DEV${NC} to ${BLUE}$DEST_PATH${NC}..."
echo "This will take a significant amount of time depending on drive size and speed."
echo "Progress will be shown."

# Use dd to create the image and gzip to compress it on the fly
sudo dd bs=4M if="$SOURCE_DEV" status=progress | gzip > "$DEST_PATH"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Backup failed! Check permissions, disk space, and drive integrity.${NC}"
    exit 1
fi

echo -e "\n${GREEN}--- BACKUP COMPLETE ---${NC}"
echo "Backup image created at: $DEST_PATH"
echo "You can restore this image later using: 'gunzip -c $DEST_PATH | sudo dd of=$SOURCE_DEV bs=4M status=progress'"

echo -e "\n${BLUE}===========================${NC}"
