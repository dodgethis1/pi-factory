#!/bin/bash
set -e

IMAGE_DIR="/home/jr/pi-images"
NVME_DEV="/dev/nvme0n1"

if [ ! -b "$NVME_DEV" ]; then
  echo "ERROR: NVMe drive not found."
  exit 1
fi

mapfile -t IMAGES < <(ls -1 "$IMAGE_DIR"/*.img "$IMAGE_DIR"/*.img.xz 2>/dev/null)

if [ "${#IMAGES[@]}" -eq 0 ]; then
  echo "No images found in $IMAGE_DIR"
  exit 1
fi

echo
echo "Available images:"
for i in "${!IMAGES[@]}"; do
  printf "  %d) %s\n" "$((i+1))" "$(basename "${IMAGES[$i]}")"
done

echo
read -rp "Select image number: " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#IMAGES[@]} )); then
  echo "Invalid selection."
  exit 1
fi

IMG_PATH="${IMAGES[$((choice-1))]}"

echo
echo "ABOUT TO WIPE $NVME_DEV"
echo "Image: $IMG_PATH"
read -rp "Type YES to continue: " confirm

if [ "$confirm" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

sudo dd if="$IMG_PATH" of="$NVME_DEV" bs=8M status=progress conv=fsync

echo "NVMe flashing complete."
