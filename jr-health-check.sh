#!/usr/bin/env bash
set -euo pipefail

TS="$(date +%F_%H%M%S)"
OUT_DIR="/var/log/jr-pi-toolkit"
OUT="$OUT_DIR/health_${TS}.log"

mkdir -p "$OUT_DIR"

{
  echo "============================================================"
  echo "JR PI TOOLKIT - HEALTH CHECK"
  echo "Time:      $(date)"
  echo "Host:      $(hostname)"
  echo "Kernel:    $(uname -a)"
  echo "User:      $(whoami)"
  echo "============================================================"
  echo

  echo "=== UPTIME / LOAD ==="
  uptime || true
  echo

  echo "=== ROOT DEVICE ==="
  findmnt -n -o SOURCE,TARGET,FSTYPE,OPTIONS / || true
  echo

  echo "=== FILESYSTEM USAGE ==="
  df -hT / || true
  echo

  echo "=== MEMORY ==="
  free -h || true
  echo

  echo "=== NETWORK (Ethernet focus) ==="
  ip -br addr || true
  echo
  ip route || true
  echo
  nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev status 2>/dev/null || true
  echo

  echo "=== WIFI RADIOS (should be OFF/unconfigured for baseline) ==="
  nmcli radio all 2>/dev/null || true
  rfkill list 2>/dev/null || true
  echo

  echo "=== NVMe (if present) ==="
  if [ -e /dev/nvme0 ]; then
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL /dev/nvme0n1 2>/dev/null || true
    echo
    command -v nvme >/dev/null 2>&1 && nvme smart-log /dev/nvme0 || true
    echo
    command -v smartctl >/dev/null 2>&1 && smartctl -a /dev/nvme0 || true
  else
    echo "No /dev/nvme0 detected"
  fi
  echo

  echo "=== KERNEL RING (errors/warnings) ==="
  dmesg -T | egrep -i "error|fail|nvme|pcie|aer|reset|timeout|I/O error|link down|ext4|mmc|watchdog|under-voltage|undervoltage|throttl|overtemp|brown" || true
  echo

  echo "=== JOURNAL (this boot, warnings+) ==="
  journalctl -b -p warning --no-pager || true
  echo

  echo "=== SSH SERVICE ==="
  systemctl status ssh --no-pager || true
  echo
} | tee "$OUT" >/dev/null

echo "Saved: $OUT"
