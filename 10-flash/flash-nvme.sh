#!/usr/bin/env bash
set -euo pipefail

# 10-flash/flash-nvme.sh
# Automated downloader and flasher for Raspberry Pi OS

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

# RPi OS Download URL (Latest 64-bit Bookworm Desktop)
# We use the official "latest" redirector to ensure we always get the newest version.
IMAGE_URL="https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64.img.xz"
LATEST_URL="https://downloads.raspberrypi.org/raspios_arm64_latest"

IMAGE_FILE="$BASE_DIR/10-flash/raspios-latest.img.xz"

# Detect NVMe
NVME_DEV="/dev/nvme0n1"

echo "=== STAGE 1: FLASH NVME ==="

# 1. Safety Checks
ROOT_DEV=$(findmnt / -o SOURCE -n)
if [[ "$ROOT_DEV" == *nvme* ]]; then
    echo "CRITICAL ERROR: You are currently booted from NVMe ($ROOT_DEV)."
    echo "Cannot flash the drive we are standing on."
    echo "Please boot from the Golden SD/USB to run this step."
    exit 1
fi

if [[ ! -b "$NVME_DEV" ]]; then
    echo "ERROR: NVMe drive $NVME_DEV not found."
    exit 1
fi

echo "Target Drive: $NVME_DEV"
echo "WARNING: ALL DATA ON $NVME_DEV WILL BE ERASED."
echo "Type 'DESTROY' to continue:"
read -r confirmation
if [[ "$confirmation" != "DESTROY" ]]; then
    echo "Aborted."
    exit 1
fi

# 2. Download Image (Always fetch fresh latest)
echo "Downloading LATEST Raspberry Pi OS (64-bit)..."
echo "URL: $LATEST_URL"
# We delete any old image to force a fresh download of the latest
rm -f "$IMAGE_FILE" 

curl -L -o "$IMAGE_FILE" "$LATEST_URL"

# Verify download
if [[ ! -s "$IMAGE_FILE" ]]; then
    echo "ERROR: Download failed or file is empty."
    exit 1
fi

# 3. Flash
echo "Unmounting any existing partitions on target..."
umount "${NVME_DEV}p1" "${NVME_DEV}p2" 2>/dev/null || true

echo "Flashing NVMe... (This may take a few minutes)"
xzcat "$IMAGE_FILE" | dd of="$NVME_DEV" bs=4M status=progress conv=fsync iflag=fullblock

echo "Flash Complete. Re-reading partition table..."
partprobe "$NVME_DEV" || true
sleep 3

# 4. Bootstrap Toolkit to NVMe
# We need to mount the new partitions and copy this toolkit over.
# Usually p1 is boot, p2 is root.
NVME_ROOT="${NVME_DEV}p2"
MOUNT_POINT="/mnt/nvme-bootstrap"

echo "Mounting new root filesystem ($NVME_ROOT)..."
mkdir -p "$MOUNT_POINT"
mount "$NVME_ROOT" "$MOUNT_POINT"

echo "Copying Pi-Factory toolkit to /opt/pi-factory..."
mkdir -p "$MOUNT_POINT/opt/pi-factory"
# Exclude the image file to save space/time
rsync -ax --exclude '10-flash/*.img.xz' --exclude '.git' "$BASE_DIR/" "$MOUNT_POINT/opt/pi-factory/"

echo "Setting permissions..."
# Ensure the scripts are executable on the target
chmod +x "$MOUNT_POINT/opt/pi-factory/main.sh"
chmod +x "$MOUNT_POINT/opt/pi-factory/"*/*.sh || true

echo "Installing global shortcut on target..."
TARGET_BIN="$MOUNT_POINT/usr/local/bin/pi-factory"
echo "#!/bin/bash" > "$TARGET_BIN"
echo "cd /opt/pi-factory" >> "$TARGET_BIN"
echo "sudo bash main.sh" >> "$TARGET_BIN"
chmod +x "$TARGET_BIN"

echo "Unmounting..."
umount "$MOUNT_POINT"

echo "=== STAGE 1 COMPLETE ==="
echo "The NVMe drive is now bootable."
echo "ACTION: Power off, remove this SD/USB, and boot from NVMe."
echo "Then run 'sudo /opt/pi-factory/main.sh' to continue."
