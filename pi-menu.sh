#!/bin/bash
set -e

clear
echo "============================================================"
echo " JR PI TOOLKIT — GOLDEN SD (INSTALLER / RECOVERY MEDIA)"
echo "============================================================"
echo
echo "REQUIRED WORKFLOW (HEADLESS):"
echo
echo "  1) Boot from this SD card (installer only)"
echo "  2) Run Option 1 → First-run setup (SD environment prep)"
echo "  3) Run Option 2 → Flash NVMe + seed identity (DESTRUCTIVE)"
echo "  4) Power OFF and REMOVE the SD card"
echo "  5) Boot from NVMe exactly once"
echo "     - cloud-init runs"
echo "     - user 'jr' is created"
echo "     - SSH + key access come up"
echo "     - provisioning runs automatically (one-shot)"
echo "  6) Verify SSH access to the NVMe system"
echo "     - normal operation begins here"
echo
echo "RULES:"
echo " - Option 2 wipes the NVMe completely"
echo " - Options 1 and 2 may be run in the same SD boot session"
echo " - Provisioning runs automatically on first NVMe boot"
echo " - The SD card is NOT required after installation"
echo " - Normal operation never depends on this SD"
echo
echo "============================================================"
echo
echo "Menu"
echo "----"
echo "1) First-run setup (Golden SD prep, networking, tools)"
echo "2) Flash NVMe + seed identity (DESTRUCTIVE)"
echo "3) Re-run provisioning (NVMe only — normally automatic on first NVMe boot)"
echo "4) Exit"
echo
read -rp "Select: " choice

case "$choice" in
  1)
    sudo /home/jr/pi-toolkit/jr-firstrun.sh
    ;;
  2)
    sudo /home/jr/pi-toolkit/flash-nvme-and-seed.sh
    ;;
  3)
    sudo /home/jr/pi-toolkit/jr-provision.sh
    ;;
  *)
    exit 0
    ;;
esac
