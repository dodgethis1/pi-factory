#!/bin/bash
set -e

ROOT_SRC=$(findmnt -n -o SOURCE /)

if [[ "$ROOT_SRC" != /dev/mmcblk* ]]; then
  echo "ERROR: Toolkit must be booted from SD card."
  echo "Current root: $ROOT_SRC"
  exit 1
fi

echo "JR Pi Toolkit"
echo "=============="
echo "1) First-run setup"
echo "2) Flash NVMe from image"
echo "3) Exit"
read -rp "Select: " choice

case "$choice" in
  1) /home/jr/pi-toolkit/jr-firstrun.sh ;;
  2) /home/jr/pi-toolkit/flash-nvme.sh ;;
  *) exit 0 ;;
esac
