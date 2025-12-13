#!/bin/bash
set -euo pipefail

LOG=/var/log/jr-provision.log
exec > >(tee -a "$LOG") 2>&1

echo
echo "=== JR Provision start: $(date) ==="

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root (use: sudo /home/jr/pi-toolkit/jr-provision.sh)"
  exit 1
fi

# Packages (baseline)
BASE_PKGS=(
  git curl vim rsync htop tmux
  openssh-server avahi-daemon
  ufw fail2ban
)

echo "[1/6] apt update"
apt-get update

echo "[2/6] install baseline packages"
apt-get install -y "${BASE_PKGS[@]}"

echo "[3/6] enable SSH"
systemctl enable --now ssh || true

echo "[4/6] enable firewall defaults (SSH allowed)"
ufw allow OpenSSH || true
ufw --force enable || true

echo "[5/6] try to install/enable VNC Server (for RealVNC Viewer)"
if apt-cache show realvnc-vnc-server >/dev/null 2>&1; then
  apt-get install -y realvnc-vnc-server
  systemctl enable --now vncserver-x11-serviced || true
else
  echo "NOTE: realvnc-vnc-server package not found in this OS repo. Skipping."
fi

echo "[6/6] try to install Raspberry Pi Connect"
if apt-cache show rpi-connect >/dev/null 2>&1; then
  apt-get install -y rpi-connect
  systemctl enable --now rpi-connect || true
else
  echo "NOTE: rpi-connect package not found in this OS repo. Skipping."
fi

echo "Install Pi-Apps (if missing)"
if [[ ! -d /home/jr/pi-apps ]]; then
  sudo -u jr bash -lc 'curl -fsSL https://pi-apps.io/install | bash' || \
  sudo -u jr bash -lc 'wget -qO- https://pi-apps.io/install | bash'
fi

echo "Install Pi-Apps app: All is well (if Pi-Apps CLI exists)"
if [[ -x /home/jr/pi-apps/pi-apps ]]; then
  sudo -u jr bash -lc '/home/jr/pi-apps/pi-apps install "All is well"' || true
else
  echo "NOTE: Pi-Apps CLI not found at /home/jr/pi-apps/pi-apps yet. Skipping."
fi

mkdir -p /var/lib/jr-toolkit
touch /var/lib/jr-toolkit/provision.done

echo "=== JR Provision complete: $(date) ==="
echo "Log: $LOG"
