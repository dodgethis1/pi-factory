#!/bin/bash
set -e
echo
echo "============================================================"
echo " JR PI TOOLKIT — GOLDEN SD (INSTALLER / RECOVERY MEDIA)"
echo "============================================================"
echo
echo "REQUIRED WORKFLOW (HEADLESS):"
echo
echo "  1) Boot from this SD"
echo "  2) Run Option 1 (First-run setup)"
echo "  3) Run Option 2 (Flash NVMe + seed identity)"
echo "  4) Power OFF and REMOVE SD"
echo "  5) Boot NVMe once and verify SSH"
echo "  6) (Optional) Reinsert SD and run Option 3 (Provision)"
echo
echo "RULES:"
echo " - Option 2 wipes NVMe"
echo " - Options 1 and 2 may be run in the same SD boot"
echo " - SSH works after the first NVMe boot (no provisioning required)"
echo " - Normal operation never uses this SD"
echo
echo "============================================================"
echo
echo "Menu"
echo "----"
echo "1) First-run setup (Golden SD prep, networking, tools)"
echo "2) Flash NVMe + seed identity (DESTRUCTIVE)"
echo "3) Provision target Pi (apps, config, desktop, services) [RUN ON NVMe]"
echo "4) Exit"
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
