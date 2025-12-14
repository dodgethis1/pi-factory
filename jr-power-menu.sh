#!/bin/bash
set -euo pipefail
source /opt/jr-pi-toolkit/jr-confirm.sh

while true; do
  clear
  echo "============================================================"
  echo " JR PI TOOLKIT — POWER"
  echo "============================================================"
  echo
  echo "Host: $(hostname)"
  echo "Uptime: $(uptime -p 2>/dev/null || true)"
  echo "Last boot: $(who -b 2>/dev/null | sed 's/.*boot  *//')"
  echo

  echo "1) Reboot now"
  echo "2) Power off now"
  echo "3) Restart SSH (sshd)"
  echo "0) Back"
  echo
  read -rp "Choose: " c

  case "$c" in
    1)
      echo
      echo "Type exactly: REBOOT"
      confirm_exact "REBOOT" "Confirm" || { echo "Cancelled."; sleep 1; continue; }
      sudo reboot now
      ;;
    2)
      echo
      echo "Type exactly: POWEROFF"
      confirm_exact "POWEROFF" "Confirm" || { echo "Cancelled."; sleep 1; continue; }
      sudo poweroff
      ;;
    3)
      echo
      sudo systemctl restart ssh
      echo "SSH restarted."
      read -rp "Press Enter to return: " _
      ;;
    0) break ;;
    *) echo "Invalid choice."; sleep 1 ;;
  esac
done
