#!/usr/bin/env bash
set -euo pipefail

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
USB_ROOT="/mnt/jr-backup/jr-backups"
IMG_DIR="$USB_ROOT/images"
LOG_DIR="$USB_ROOT/logs"
TS="$(date +%F_%H%M%S)"

DEV="/dev/mmcblk0"

echo "=== JR: Image Golden SD to USB ==="
echo "Root: $ROOT_SRC"
echo "SD:   $DEV"
echo "USB:  $USB_ROOT"
echo

if [[ "$ROOT_SRC" == /dev/mmcblk* ]]; then
  echo "ERROR: You are booted from SD ($ROOT_SRC)."
  echo "Boot from NVMe, insert the Golden SD, then run this again."
  exit 1
fi

if [[ ! -b "$DEV" ]]; then
  echo "ERROR: $DEV not found. Insert the Golden SD card."
  exit 1
fi

if [[ ! -d "$USB_ROOT" ]]; then
  echo "ERROR: $USB_ROOT not found."
  echo "Mount your USB and bind-mount it to /mnt/jr-backup first."
  exit 1
fi

mkdir -p "$IMG_DIR" "$LOG_DIR"

if ! command -v parted >/dev/null 2>&1; then
  echo "Installing parted (needed to calculate exact image size)..."
  sudo apt update
  sudo apt install -y parted
fi

if ! command -v xz >/dev/null 2>&1; then
  echo "Installing xz-utils..."
  sudo apt update
  sudo apt install -y xz-utils
fi

OUT_IMG="$IMG_DIR/golden-sd_${TS}.img.xz"
OUT_LOG="$LOG_DIR/golden-sd_${TS}.log"

echo "Writing: $OUT_IMG"
echo "Log:     $OUT_LOG"
echo

# Find last partition end sector (exact size, so smaller targets are possible later)
END_SECTOR="$(parted -ms "$DEV" unit s print | awk -F: '$1 ~ /^[0-9]+$/ {gsub(/s/,"",$3); end=$3} END {print end+0}')"

if [[ -z "${END_SECTOR:-}" || "$END_SECTOR" -le 0 ]]; then
  echo "ERROR: Could not determine end sector for $DEV"
  exit 1
fi

SECTORS_TO_COPY=$((END_SECTOR + 1))
BYTES_TO_COPY=$((SECTORS_TO_COPY * 512))

{
  echo "=== INFO ==="
  echo "Device:        $DEV"
  echo "End sector:    $END_SECTOR"
  echo "Sectors copied:$SECTORS_TO_COPY"
  echo "Bytes copied:  $BYTES_TO_COPY"
  echo
  echo "=== lsblk ==="
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL "$DEV" || true
  echo
  echo "=== dd + xz start: $(date) ==="
} | tee "$OUT_LOG" >/dev/null

# Exact copy (512-byte sectors), compressed.
# status=progress gives you a live byte counter.
sudo dd if="$DEV" bs=512 count="$SECTORS_TO_COPY" status=progress \
  | xz -T0 -c \
  | tee "$OUT_IMG" >/dev/null

{
  echo
  echo "=== dd + xz done: $(date) ==="
  echo "Output: $OUT_IMG"
  echo "Size:   $(ls -lh "$OUT_IMG" | awk "{print \$5}")"
  echo "SHA256: $(sha256sum "$OUT_IMG" | awk "{print \$1}")"
} | tee -a "$OUT_LOG" >/dev/null

echo
echo "DONE: $OUT_IMG"
echo "LOG:  $OUT_LOG"
