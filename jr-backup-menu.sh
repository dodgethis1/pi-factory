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

show_usb_status() {
  echo "----- Mount status -----"
  if mountpoint -q "${USB_MOUNT}"; then
    mount | grep " on ${USB_MOUNT} " || true
    df -h "${USB_MOUNT}" || true
  else
    echo "NOT mounted: ${USB_MOUNT}"
  fi
  echo
  echo "----- Devices (lsblk) -----"
  lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,MODEL
  echo
}

mount_backup_usb() {
  mkdir -p "${USB_MOUNT}"

  if mountpoint -q "${USB_MOUNT}"; then
    echo "OK: already mounted at ${USB_MOUNT}"
    return 0
  fi

  echo "Attempting: sudo mount ${USB_MOUNT} (uses /etc/fstab if present)"
  if sudo mount "${USB_MOUNT}"; then
    echo "OK: mounted ${USB_MOUNT}"
    return 0
  fi

  echo
  echo "ERROR: Could not mount ${USB_MOUNT}."
  echo "Common causes:"
  echo " - No /etc/fstab entry for the backup drive"
  echo " - Wrong UUID in /etc/fstab"
  echo " - Drive not plugged in / not detected"
  echo
  show_usb_status
  return 1
}

ensure_usb() {
  mkdir -p "${USB_MOUNT}"

  if ! mountpoint -q "${USB_MOUNT}"; then
    echo "Backup USB is not mounted at ${USB_MOUNT}."
    echo
    echo "Use: 5) Mount/Check backup USB"
    echo
    return 1
  fi

  mkdir -p "${USB_ROOT}"
  return 0
}

while true; do
  header
  echo "0) Back"
  echo "1) Show disk + USB status (lsblk/df)"
  echo "2) Create/verify USB folder structure"
  echo "3) Image Golden SD -> USB (jr-image-golden-sd-to-usb.sh)"
  echo "4) Sanitize for imaging (jr-sanitize-for-imaging.sh)"
  echo "5) Mount/Check backup USB (${USB_MOUNT})"
  echo

  read -r -p "Choose: " choice
  case "${choice}" in
    0)
      break
      ;;
    1)
      show_usb_status
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
    5)
      mount_backup_usb
      pause
      ;;
    *)
      echo "Pick 0-5."
      pause
      ;;
  esac
done
