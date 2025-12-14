#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_MOUNT="/mnt/jr-backup"
USB_ROOT="${USB_MOUNT}/jr-backups"

pause() { echo; echo "Press Enter to continue..."; read -r _; }

header() {
  clear
  echo "==============================================================="
  echo "  JR PI TOOLKIT - BACKUP / IMAGING"
  echo "==============================================================="
  echo
  echo "USB mount: ${USB_MOUNT}"
  echo "USB root : ${USB_ROOT}"
  echo
}

ensure_usb() {
  if ! mountpoint -q "${USB_MOUNT}"; then
    echo "ERROR: ${USB_MOUNT} is not mounted."
    echo "Fix: plug in the backup USB and run:  sudo mount -a"
    echo
    return 1
  fi

  mkdir -p "${USB_ROOT}"
  return 0
}

while true; do
  header
  echo "1) Show disk + USB status (lsblk/df)"
  echo "2) Create/verify USB folder structure"
  echo "3) Image Golden SD -> USB (jr-image-golden-sd-to-usb.sh)"
  echo "4) Sanitize for imaging (jr-sanitize-for-imaging.sh)"
  echo "0) Back"
  echo

  read -r -p "Choose: " choice
  case "${choice}" in
    1)
      lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,MODEL
      echo
      timeout 2s df -h "" 2>/dev/null || echo "(df timed out or not mounted)"
      pause
      ;;
    2)
      if ensure_usb; then
        echo "OK: ${USB_ROOT} is ready."
        echo
        find "${USB_MOUNT}" -maxdepth 2 -type d -print 2>/dev/null || true
      fi
      pause
      ;;
    3)
      if ensure_usb; then
        bash "${SCRIPT_DIR}/jr-image-golden-sd-to-usb.sh"
      fi
      pause
      ;;
    4)
      bash "${SCRIPT_DIR}/jr-sanitize-for-imaging.sh"
      pause
      ;;
    0)
      exit 0
      ;;
    *)
      echo "Pick 0-4."
      pause
      ;;
  esac
done
