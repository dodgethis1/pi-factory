#!/usr/bin/env bash
set -euo pipefail

pause(){ read -rp "Press Enter to return..." _; }

while true; do
  clear
  echo "============================================================"
  echo " JR PI TOOLKIT — BACKUP / IMAGING"
  echo "============================================================"
  echo
  echo "USB root: /mnt/jr-backup/jr-backups"
  echo

  if [[ -d /mnt/jr-backup/jr-backups ]]; then
    echo "Backup target: OK"
  else
    echo "Backup target: MISSING"
    echo "Fix: mount USB and bind-mount to /mnt/jr-backup first."
  fi

  echo
  echo "1) Image Golden SD (/dev/mmcblk0) -> USB (.img.xz)"
  echo "2) Sanitize this OS for cloning (removes machine-id + SSH host keys)"
  echo "3) Exit"
  echo
  read -rp "Select: " c

  case "${c:-}" in
    1)
      sudo /opt/jr-pi-toolkit/jr-image-golden-sd-to-usb.sh
      pause
      ;;
    2)
      sudo /opt/jr-pi-toolkit/jr-sanitize-for-imaging.sh
      pause
      ;;
    3)
      exit 0
      ;;
    *)
      echo "Invalid selection."
      sleep 1
      ;;
  esac
done
