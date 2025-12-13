#!/bin/bash
set -euo pipefail

# Flash NVMe from image (numbered picker)
# Assumes toolkit is booted from SD

IMG_DIR="/home/jr/pi-images"
NVME_DEV="/dev/nvme0n1"

echo
echo "=== JR NVMe Flash Tool ==="
echo

# Safety check: must be booted from SD
ROOT_SRC=$(findmnt -n -o SOURCE /)
if [[ "$ROOT_SRC" != /dev/mmcblk* ]]; then
  echo "ERROR: Toolkit must be booted from SD card."
  echo "Current root device: $ROOT_SRC"
  exit 1
fi

# Confirm NVMe exists
if [[ ! -b "$NVME_DEV" ]]; then
  echo "ERROR: NVMe device $NVME_DEV not found."
  lsblk
  exit 1
fi

# Find images
mapfile -t IMAGES < <(ls -1 "$IMG_DIR"/*.img.xz 2>/dev/null | xargs -n1 basename)

if [[ "${#IMAGES[@]}" -eq 0 ]]; then
  echo "ERROR: No .img.xz files found in $IMG_DIR"
  exit 1
fi

echo "Available images:"
for i in "${!IMAGES[@]}"; do
  printf "  %d) %s\n" $((i+1)) "${IMAGES[$i]}"
done
echo

read -rp "Pick image number (1-${#IMAGES[@]}): " PICK

if ! [[ "$PICK" =~ ^[0-9]+$ ]] || [[ "$PICK" -lt 1 ]] || [[ "$PICK" -gt "${#IMAGES[@]}" ]]; then
  echo "Invalid selection."
  exit 1
fi

IMAGE="${IMAGES[$((PICK-1))]}"
IMG_PATH="$IMG_DIR/$IMAGE"

echo
echo "ABOUT TO WIPE: $NVME_DEV"
echo "IMAGE: $IMG_PATH"
echo
read -rp "Type YES to continue: " CONFIRM

if [[ "$CONFIRM" != "YES" ]]; then
  echo "Aborted."
  exit 1
fi

echo
echo "Flashing NVMe..."
xzcat "$IMG_PATH" | sudo dd of="$NVME_DEV" bs=4M status=progress conv=fsync

echo
echo "NVMe flashing complete."
echo

