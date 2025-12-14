#!/usr/bin/env bash
set -euo pipefail

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"

TOOLKIT_SD="/home/jr/pi-toolkit"
TOOLKIT_NVME="/opt/jr-pi-toolkit"

# BOOT MODE MUST BE BASED ON ROOT DEVICE ONLY (leftover dirs shouldn't matter)
if [[ "$ROOT_SRC" == /dev/mmcblk* ]]; then
  BOOT_MODE="SD"
  TOOLKIT_ROOT="$TOOLKIT_SD"
else
  BOOT_MODE="NVME"
  TOOLKIT_ROOT="$TOOLKIT_NVME"
fi

pause() { read -rp "Press Enter to return to menu..." _; }

confirm_phrase() {
  local phrase="$1"
  echo
  echo "CONFIRM REQUIRED"
  echo "Type exactly: $phrase"
  read -rp "> " typed
  [[ "${typed:-}" == "$phrase" ]]
}

while true; do
clear || true  echo "============================================================"
  echo " JR PI TOOLKIT — GOLDEN SD / NVMe TOOLKIT (HEADLESS SAFE)"
  echo "============================================================"
  echo
  echo "Detected root: $ROOT_SRC"
  echo "Toolkit root:  $TOOLKIT_ROOT"
  if [[ -x /home/jr/pi-apps/pi-apps || -x /home/jr/pi-apps/updater ]]; then
    echo "Pi-Apps:      installed (/home/jr/pi-apps)"
  else
    echo "Pi-Apps:      not installed"
  fi
  echo

  echo "Menu"
  echo "----"
  echo "0) Set NVMe first-boot network (Ethernet/Wi-Fi)          [SD only]"
  echo "1) First-run setup (Golden SD prep, networking, tools)   [SD only]"
  echo "2) Flash NVMe + seed identity (DESTRUCTIVE)              [SD only]"
  echo "3) Re-run provisioning                                   [NVMe only]"
  echo "4) Exit"
  echo "5) Install Pi-Apps (menu-driven)                         [NVMe only]"
  echo "6) Health Check (log to /var/log/jr-pi-toolkit)          [NVMe only]"
  echo "7) Backup / Imaging (SD image, sanitize)                 [NVMe only]"
  echo "9) Help / Checklist (what to do, in what order)"
  echo
  read -rp "Select: " choice

  case "${choice:-}" in
    0)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-set-nvme-network.sh"
      pause
      ;;
    1)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-firstrun.sh"
      pause
      ;;
    2)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      if ! confirm_phrase "FLASH_NVME_ERASE_ALL"; then
        echo "Canceled."
        pause
        continue
      fi
      sudo "$TOOLKIT_ROOT/flash-nvme-and-seed.sh"
      pause
      ;;
    3)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      if ! confirm_phrase "RUN_PROVISION_ON_NVME"; then
        echo "Canceled."
        pause
        continue
      fi
      sudo "$TOOLKIT_ROOT/jr-provision.sh"
      pause
      ;;
    4)
      echo "Exiting JR Pi Toolkit."
      exit 0
      ;;
    5)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-install-pi-apps.sh" ]] || { echo "ERROR: Missing jr-install-pi-apps.sh"; pause; continue; }
      sudo -u jr -H bash -lc "$TOOLKIT_ROOT/jr-install-pi-apps.sh"
      pause
      ;;
    6)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-health-check.sh" ]] || { echo "ERROR: Missing jr-health-check.sh"; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-health-check.sh"
      pause
      ;;
    7)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-backup-menu.sh" ]] || { echo "ERROR: Missing jr-backup-menu.sh"; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-backup-menu.sh"
      pause
      ;;
    9)
      echo
      echo "CHECKLIST (Golden SD -> NVMe, headless)"
      echo "1) Boot from Golden SD (installer only)."
      echo "2) Run Option 1 (first-run SD prep)."
      echo "3) Run Option 2 (flash NVMe + seed identity)."
      echo "4) Power off, remove SD."
      echo "5) Boot from NVMe once. SSH should come up as jr with keys."
      echo "6) From NVMe, run provisioning only when YOU choose (Option 3)."
      echo "7) Pi-Apps and workload installs are menu items, not automatic."
      echo
      pause
      ;;
    *)
      echo "Invalid selection."
      sleep 1
      ;;
  esac
done
