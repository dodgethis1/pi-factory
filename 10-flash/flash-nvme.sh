#!/usr/bin/env bash
set -euo pipefail

# 10-flash/flash-nvme.sh
# Automated downloader and flasher for Raspberry Pi OS

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# RPi OS Download URL
IMAGE_URL="https://downloads.raspberrypi.org/raspios_full_arm64_latest"
LATEST_URL="https://downloads.raspberrypi.org/raspios_full_arm64_latest"
IMAGE_FILE="$BASE_DIR/10-flash/raspios-full-latest.img.xz"

# Detect NVMe
NVME_DEV="/dev/nvme0n1"

echo -e "${BLUE}=== STAGE 1: FLASH NVME ===${NC}"

# 1. Safety Checks
ROOT_DEV=$(findmnt / -o SOURCE -n)
if [[ "$ROOT_DEV" == *nvme* ]]; then
    echo -e "${RED}CRITICAL ERROR: You are currently booted from NVMe ($ROOT_DEV).${NC}"
    echo "Cannot flash the drive we are standing on."
    echo "Please boot from the Golden SD/USB to run this step."
    exit 1
fi

if [[ ! -b "$NVME_DEV" ]]; then
    echo -e "${RED}ERROR: NVMe drive $NVME_DEV not found.${NC}"
    echo "Please check your ribbon cable connection."
    exit 1
fi

# Safety Check: Verify drive size
DRIVE_SIZE=$(blockdev --getsize64 "$NVME_DEV" 2>/dev/null || echo 0)
if [[ "$DRIVE_SIZE" -lt 4000000000 ]]; then
    echo -e "${RED}CRITICAL ERROR: Target drive reported size is too small ($DRIVE_SIZE bytes).${NC}"
    echo "This indicates the drive has disconnected or is failing."
    exit 1
fi

# --- SAFETY WIZARD ---
MODEL=$(lsblk -no MODEL "$NVME_DEV" | head -n1)
SERIAL=$(lsblk -no SERIAL "$NVME_DEV" | head -n1)
SIZE_HUMAN=$(lsblk -no SIZE "$NVME_DEV" | head -n1)

echo -e "${RED}================================================================${NC}"
echo -e "${RED}${BOLD}   DANGER ZONE: NVMe FLASHING PROTOCOL   ${NC}"
echo -e "${RED}================================================================${NC}"
echo
echo -e "You are about to ${BOLD}COMPLETELY WIPE${NC} the following drive:"
echo
echo -e "   Device Node: ${YELLOW}$NVME_DEV${NC}"
echo -e "   Model:       ${YELLOW}$MODEL${NC}"
echo -e "   Serial:      ${YELLOW}$SERIAL${NC}"
echo -e "   Capacity:    ${YELLOW}$SIZE_HUMAN${NC}"
echo
echo "----------------------------------------------------------------"
echo "Please verify the following:"
echo "1. I have identified this as the correct target drive."
echo "2. I have backed up any critical data from this drive."
echo "3. I understand this action is IRREVERSIBLE."
echo "----------------------------------------------------------------"
echo 

read -rp "Are you absolutely sure you want to proceed? (yes/no): " CONFIRM_1
if [[ "${CONFIRM_1,,}" != "yes" ]]; then
    echo "Aborted by user."
    exit 1
fi

echo
echo -e "${RED}FINAL WARNING: PERFORMING DATA DESTRUCTION.${NC}"
echo "To confirm, type the word 'DESTROY' (all caps):"
read -r CONFIRM_2
if [[ "$CONFIRM_2" != "DESTROY" ]]; then
    echo "Safety check failed. Aborted."
    exit 1
fi

# 2. Download Image
echo -e "\n${YELLOW}--- Downloading Raspberry Pi OS ---${NC}"
echo "URL: $LATEST_URL"
curl -L -R -z "$IMAGE_FILE" -o "$IMAGE_FILE" "$LATEST_URL"

if [[ ! -s "$IMAGE_FILE" ]]; then
    echo -e "${RED}ERROR: Download failed or file is empty.${NC}"
    exit 1
fi

# 3. Flash
echo -e "\n${YELLOW}--- Flashing NVMe Drive ---${NC}"
echo "Unmounting target..."
umount "${NVME_DEV}p1" "${NVME_DEV}p2" 2>/dev/null || true

echo "Writing image... (This may take a few minutes)"
xzcat "$IMAGE_FILE" | dd of="$NVME_DEV" bs=4M status=progress conv=fsync iflag=fullblock

echo "Flash Complete. Re-reading partition table..."
partprobe "$NVME_DEV" || true
udevadm settle || true
sleep 3

if [[ ! -b "${NVME_DEV}p2" ]]; then
    echo -e "${RED}ERROR: Partition ${NVME_DEV}p2 not found after flashing.${NC}"
    lsblk "$NVME_DEV"
    exit 1
fi

# 4. Bootstrap Toolkit
echo -e "\n${YELLOW}--- Bootstrapping Toolkit ---${NC}"
NVME_ROOT="${NVME_DEV}p2"
MOUNT_POINT="/mnt/nvme-bootstrap"

mkdir -p "$MOUNT_POINT"
mount "$NVME_ROOT" "$MOUNT_POINT"

echo "Copying Pi-Factory toolkit to /opt/pi-factory..."
mkdir -p "$MOUNT_POINT/opt/pi-factory"
rsync -ax --exclude '10-flash/*.img.xz' --exclude '.git' "$BASE_DIR/" "$MOUNT_POINT/opt/pi-factory/"

echo "Setting permissions..."
chmod +x "$MOUNT_POINT/opt/pi-factory/main.sh"
chmod +x "$MOUNT_POINT/opt/pi-factory/"*/*.sh || true

echo "Installing global shortcut..."
TARGET_BIN="$MOUNT_POINT/usr/local/bin/pi-factory"
echo "#!/bin/bash" > "$TARGET_BIN"
echo "cd /opt/pi-factory" >> "$TARGET_BIN"
echo "sudo bash main.sh" >> "$TARGET_BIN"
chmod +x "$TARGET_BIN"

umount "$MOUNT_POINT"

echo -e "\n${GREEN}=== FLASHING COMPLETE ===${NC}"
echo "The NVMe drive is now bootable."
echo "ACTION: Power off, remove this SD/USB, and boot from NVMe."