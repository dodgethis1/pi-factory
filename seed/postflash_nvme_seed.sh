#!/usr/bin/env bash
set -euo pipefail

NVME_BOOT="/dev/nvme0n1p1"
NVME_ROOT="/dev/nvme0n1p2"
MNT_BOOT="/mnt/nvme-boot"
MNT_ROOT="/mnt/nvme-root"

# Key material lives outside repo (trusted golden SD)
SEED_KEYS="/home/jr/seed/jr-authorized_keys"

die() { echo "ERROR: $*" >&2; exit 1; }

echo "[seed] Mounting NVMe boot + root..."
sudo mkdir -p "$MNT_BOOT" "$MNT_ROOT"
sudo mount "$NVME_BOOT" "$MNT_BOOT"
sudo mount "$NVME_ROOT" "$MNT_ROOT"

cleanup() {
  echo "[seed] Sync + unmount..."
  sync
  sudo umount "$MNT_BOOT" 2>/dev/null || true
  sudo umount "$MNT_ROOT" 2>/dev/null || true
}
trap cleanup EXIT

# Read pubkey
[[ -f "$SEED_KEYS" ]] || die "Missing seed keys file: $SEED_KEYS"
PUBKEY="$(cat "$SEED_KEYS")"
[[ -n "${PUBKEY}" ]] || die "Seed keys file is empty: $SEED_KEYS"

# Detect cloud-init style boot partition (Debian cloud images)
CLOUDINIT=false
if [[ -f "$MNT_BOOT/user-data" && -f "$MNT_BOOT/meta-data" && -f "$MNT_BOOT/network-config" ]]; then
  CLOUDINIT=true
fi

echo "[seed] Detected image type: $([[ "$CLOUDINIT" == true ]] && echo cloud-init || echo non-cloud-init)"

# Prompt once for jr password hash (interactive by design)
echo "[seed] Creating password hash for user 'jr' (you will be prompted)..."
HASH="$(openssl passwd -6)"

if [[ "$CLOUDINIT" == true ]]; then
  echo "[seed] Cloud-init image: patching user-data + network-config for headless SSH..."

  # Backups
  sudo cp -a "$MNT_BOOT/user-data" "$MNT_BOOT/user-data.bak.$(date +%Y%m%d-%H%M%S)"
  sudo cp -a "$MNT_BOOT/network-config" "$MNT_BOOT/network-config.bak.$(date +%Y%m%d-%H%M%S)"

  # Write cloud-init user-data
  # Notes:
  # - ssh_pwauth true (per your requirement: keep password auth initially)
  # - installs openssh-server
  # - forces unique host keys (avoids cloned fingerprints)
  # - enables ssh
  sudo tee "$MNT_BOOT/user-data" >/dev/null <<USERDATA
#cloud-config
users:
  - name: jr
    gecos: jr
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: ${HASH}
    ssh_authorized_keys:
      - "${PUBKEY}"

ssh_pwauth: true

package_update: true
packages:
  - openssh-server

runcmd:
  - [ sh, -lc, 'rm -f /etc/ssh/ssh_host_* || true' ]
  - [ sh, -lc, 'ssh-keygen -A' ]
  - [ sh, -lc, 'systemctl enable --now ssh || systemctl enable --now sshd || true' ]
  - [ sh, -lc, 'systemctl restart ssh || systemctl restart sshd || true' ]
  - [ sh, -lc, 'mkdir -p /var/lib/jr-toolkit && touch /var/lib/jr-toolkit/seed.done' ]
USERDATA

  # Write network-config: require eth0 DHCP so cloud-init waits for network
  sudo tee "$MNT_BOOT/network-config" >/dev/null <<'NETCFG'
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      optional: false
NETCFG

  echo "[seed] Cloud-init patch complete."
else
  echo "[seed] Non-cloud-init image: applying Pi-OS-style compat seeding..."

  # Pi OS style SSH enable triggers (harmless if unused)
  sudo touch "$MNT_BOOT/ssh" 2>/dev/null || true
  sudo touch "$MNT_BOOT/firmware/ssh" 2>/dev/null || true

  # Pi OS userconf.txt (only meaningful on Pi OS images that honor it)
  echo "jr:$HASH" | sudo tee "$MNT_BOOT/userconf.txt" >/dev/null || true

  # Seed authorized_keys into rootfs (generic Linux)
  sudo mkdir -p "$MNT_ROOT/home/jr/.ssh"
  sudo install -m 600 "$SEED_KEYS" "$MNT_ROOT/home/jr/.ssh/authorized_keys"
  sudo chmod 700 "$MNT_ROOT/home/jr/.ssh"
  sudo chown -R 1000:1000 "$MNT_ROOT/home/jr/.ssh" || true

  # Best-effort host key reset (if ssh exists in image)
  sudo rm -f "$MNT_ROOT/etc/ssh/ssh_host_"* 2>/dev/null || true

  echo "[seed] Non-cloud-init seeding complete."
fi

echo "[seed] Done."
