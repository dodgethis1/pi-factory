#!/bin/bash
set -euo pipefail

echo "=== BOOT ==="
findmnt -n -o SOURCE / && findmnt -n -o SOURCE /boot/firmware
echo

echo "=== ID ==="
hostname
ip -br addr | sed 's/^/  /'
echo

echo "=== ROUTE ==="
ip route | sed 's/^/  /' | head -n 10
echo

echo "=== WIFI (should be blocked/unconfigured) ==="
rfkill list wifi 2>/dev/null || true
nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null || true
echo

echo "=== BACKUP USB ==="
findmnt /mnt/jr-backup 2>/dev/null || echo "  /mnt/jr-backup not mounted"
ls -la /mnt/jr-backup 2>/dev/null | head -n 20 || true
echo

echo "=== TOOLKIT GIT ==="
git -C /opt/jr-pi-toolkit status -sb || true
git -C /opt/jr-pi-toolkit rev-parse --short HEAD 2>/dev/null || true
