#!/usr/bin/env bash
set -euo pipefail

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
if [[ "$ROOT_SRC" == /dev/mmcblk* ]]; then
  echo "ERROR: Pi-Apps install must be run from NVMe (not the Golden SD)."
  exit 1
fi

echo "============================================================"
echo "Pi-Apps installer (NVMe-only, menu-driven)"
echo "User: $(whoami)"
echo "Host: $(hostname)"
echo "Time: $(date)"
echo "============================================================"
echo

# Dependencies (Pi-Apps needs git; curl is for fetching the raw installer)
sudo apt update
sudo apt install -y curl git

PI_APPS_DIR="$HOME/pi-apps"

if [[ -d "$PI_APPS_DIR" ]]; then
  echo "Pi-Apps appears to already be installed at: $PI_APPS_DIR"
  echo
  echo "Choose:"
  echo "  1) Update Pi-Apps"
  echo "  2) Reinstall Pi-Apps (keeps folder, reruns installer)"
  echo "  3) Exit"
  echo
  read -rp "Select: " c

  case "${c:-}" in
    1)
      if [[ -x "$PI_APPS_DIR/updater" ]]; then
        "$PI_APPS_DIR/updater"
      elif [[ -x "$PI_APPS_DIR/pi-apps" ]]; then
        "$PI_APPS_DIR/pi-apps" update || true
      else
        echo "Updater not found. Doing a git pull instead."
        git -C "$PI_APPS_DIR" pull --ff-only
      fi
      ;;
    2)
      echo "Re-running installer..."
      curl -fsSL "https://raw.githubusercontent.com/Botspot/pi-apps/master/install" | bash
      ;;
    3)
      echo "Exit."
      exit 0
      ;;
    *)
      echo "Invalid selection."
      exit 1
      ;;
  esac
else
  echo "Pi-Apps not detected. Installing fresh..."
  echo
  curl -fsSL "https://raw.githubusercontent.com/Botspot/pi-apps/master/install" | bash
fi

echo
echo "Done."
echo "Launch Pi-Apps from the menu or run: $PI_APPS_DIR/pi-apps"
