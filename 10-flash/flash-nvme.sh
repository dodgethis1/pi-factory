#!/usr/bin/env bash
set -euo pipefail

# 10-flash/flash-nvme.sh
# Automated downloader and flasher for Raspberry Pi OS

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

# RPi OS Download URL (Latest 64-bit Bookworm)
# We can use the 'raspios_arm64_latest' redirector
IMAGE_URL="https://downloads.raspberrypi.com/raspios_arm64/images/raspios_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64.img.xz"
# Note: A static URL is safer for a script than parsing HTML, but it goes stale.
# Better approach: Use the 'latest' redirector if possible, or accept the risk.
# For stability, I'll use the specific "Bookworm" latest link if available, 
# but usually https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2024-07-04/...
# Let's use the 'latest' symlink approach if we can, or just hardcode the known "Latest" for now 
# and add a TODO to make it dynamic.
# Actually, the direct link to "latest" is:
LATEST_URL="https://downloads.raspberrypi.org/raspios_arm64/images/raspios_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64.img.xz"
# Start with a fixed reliable URL for the "latest" known stable. 
# Update this if the user wants strictly "latest available at runtime".

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

# 2. Download Image (if not present)
if [[ ! -f "$IMAGE_FILE" ]]; then
    echo "Downloading Raspberry Pi OS (64-bit)..."
    # We use curl with -L to follow redirects
    # NOTE: In a real script, we might scrape the https://downloads.raspberrypi.org/raspios_arm64/images/ page
    # to find the absolute latest. For now, we will assume we want the latest known stable.
    # To be truly robust, let's use the 'latest' zip if possible, or just ask the user to provide it.
    # Let's try downloading the 'latest' redirect.
    echo "Fetching from $LATEST_URL ..."
    curl -L -o "$IMAGE_FILE" "$LATEST_URL"
else
    echo "Using existing image: $IMAGE_FILE"
fi

# 3. Flash
echo "Flashing NVMe... (This may take a few minutes)"
xzcat "$IMAGE_FILE" | dd of="$NVME_DEV" bs=4M status=progress conv=fsync

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

echo "Unmounting..."
umount "$MOUNT_POINT"

echo "=== STAGE 1 COMPLETE ==="
echo "The NVMe drive is now bootable."
echo "ACTION: Power off, remove this SD/USB, and boot from NVMe."
echo "Then run 'sudo /opt/pi-factory/main.sh' to continue."
