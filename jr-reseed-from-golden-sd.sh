#!/bin/bash
set -euo pipefail
source /opt/jr-pi-toolkit/jr-confirm.sh

SD_PART="/dev/mmcblk0p2"
MNT="/mnt/jr-golden-sd"

echo
echo "============================================================"
echo " JR PI TOOLKIT — RE-SEED USER IDENTITY FROM GOLDEN SD"
echo "============================================================"
echo
echo "This expects the Golden SD is inserted (mmcblk0p2)."
echo "It will copy USER ssh files from SD -> this NVMe OS."
echo
echo "Type exactly: RESEED"
echo

confirm_exact "RESEED" "Confirm" || die "Cancelled."

[ -b "$SD_PART" ] || die "Golden SD not detected at $SD_PART. Insert SD and retry."

sudo mkdir -p "$MNT"
if ! mountpoint -q "$MNT"; then
  sudo mount -o ro "$SD_PART" "$MNT"
fi

SRC="$MNT/home/jr/.ssh"
DST="/home/jr/.ssh"

[ -d "$SRC" ] || die "No $SRC on Golden SD."

mkdir -p "$DST"
chmod 700 "$DST"

copy_one() {
  local f="$1"
  if [ -f "$SRC/$f" ]; then
    install -m 600 -o jr -g jr "$SRC/$f" "$DST/$f"
    echo "Copied: $f"
  fi
}

echo
echo "Copying user SSH files..."
copy_one authorized_keys
copy_one config
copy_one id_ed25519_github
copy_one id_ed25519_github.pub
copy_one id_ed25519_golden_sd
copy_one id_ed25519_golden_sd.pub
copy_one known_hosts
copy_one known_hosts.old

echo
echo "Fixing perms..."
sudo chown -R jr:jr "$DST"
chmod 700 "$DST"
chmod 600 "$DST"/* 2>/dev/null || true

echo
echo "Unmounting SD..."
sudo umount "$MNT" || true

echo
echo "Done. Test GitHub auth with:"
echo "  ssh -T git@github.com"
