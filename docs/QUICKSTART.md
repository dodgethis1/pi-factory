# Quickstart (Golden SD -> NVMe)

## Golden SD (installer mode)
1) Boot the Pi from the Golden SD.
2) Run the menu:
   - cd /opt/jr-pi-toolkit (or wherever the toolkit lives)
   - bash ./pi-menu.sh
3) Run in order:
   - Option 1: Set NVMe first-boot network
   - Option 2: First-run setup (Golden SD prep)
   - Option 3: Flash NVMe + seed identity (DESTRUCTIVE, confirmation required)
4) Power off. Remove the SD card.

## NVMe (runtime mode)
5) Boot from NVMe.
6) Run the menu again:
   - bash ./pi-menu.sh
7) Run:
   - Option 4: Provisioning (when you choose)
   - Option 5: Pi-Apps (optional)
8) Use:
   - Option 8: Status
   - Option L: View last run log

Tip: If something feels weird, run Doctor/Preflight first.
