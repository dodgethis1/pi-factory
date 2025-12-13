#!/usr/bin/env bash
set -euo pipefail

NVME_BOOT="/dev/nvme0n1p1"
MNT_BOOT="/mnt/nvme-boot"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root: sudo /home/jr/pi-toolkit/jr-set-nvme-network.sh"
  exit 1
fi

if [[ ! -b "$NVME_BOOT" ]]; then
  echo "ERROR: NVMe boot partition not found: $NVME_BOOT"
  lsblk
  exit 1
fi

mkdir -p "$MNT_BOOT"
mountpoint -q "$MNT_BOOT" || mount "$NVME_BOOT" "$MNT_BOOT"

CFG="$MNT_BOOT/network-config"
if [[ -f "$CFG" ]]; then
  cp -a "$CFG" "${CFG}.bak.$(date +%Y%m%d-%H%M%S)"
fi

echo
echo "NVMe first-boot network (cloud-init / netplan):"
echo "  1) Ethernet DHCP only"
echo "  2) Wi-Fi only (wlan0)"
echo "  3) Both (Ethernet DHCP + Wi-Fi fallback)"
echo
read -rp "Select (1-3): " MODE

SSID=""
PSK=""
if [[ "$MODE" == "2" || "$MODE" == "3" ]]; then
  read -rp "Wi-Fi SSID: " SSID
  read -rsp "Wi-Fi Password: " PSK
  echo
  if [[ -z "$SSID" || -z "$PSK" ]]; then
    echo "ERROR: SSID/password cannot be empty."
    umount "$MNT_BOOT" || true
    exit 1
  fi
fi

case "$MODE" in
  1)
    cat > "$CFG" <<YAML
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      optional: false
YAML
    ;;
  2)
    cat > "$CFG" <<YAML
network:
  version: 2
  wifis:
    wlan0:
      dhcp4: true
      optional: false
      access-points:
        "${SSID}":
          password: "${PSK}"
YAML
    ;;
  3)
    cat > "$CFG" <<YAML
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      optional: true
  wifis:
    wlan0:
      dhcp4: true
      optional: false
      access-points:
        "${SSID}":
          password: "${PSK}"
YAML
    ;;
  *)
    echo "Invalid selection."
    umount "$MNT_BOOT" || true
    exit 1
    ;;
esac

echo
echo "Wrote: $CFG"
echo "Preview:"
echo "--------------------------------"
sed -n '1,120p' "$CFG"
echo "--------------------------------"

sync
umount "$MNT_BOOT" || true

echo "Done."
