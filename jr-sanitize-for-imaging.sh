#!/usr/bin/env bash
set -euo pipefail

echo "=== SANITIZE FOR IMAGING (safe to clone afterward) ==="
echo "This removes machine identity + SSH host keys so clones don't conflict."
echo

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root (use sudo)."
  exit 1
fi

echo "Removing SSH host keys..."
rm -f /etc/ssh/ssh_host_* || true

echo "Removing machine-id..."
rm -f /etc/machine-id /var/lib/dbus/machine-id || true
systemd-machine-id-setup >/dev/null 2>&1 || true

echo "Clearing cloud-init instance state (if present)..."
rm -rf /var/lib/cloud/instances/* 2>/dev/null || true
rm -f /var/lib/cloud/instance/obj.pkl 2>/dev/null || true

echo "Done."
echo "Recommendation: reboot before imaging to ensure regenerated identity is clean."
