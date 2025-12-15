#!/usr/bin/env bash
set -euo pipefail

# 20-configure/seed-nvme.sh
# "Offline" configuration for the NVMe drive.
# run this from the Golden SD to prep the NVMe for its first boot.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
KEYS_DIR="$BASE_DIR/config/keys"
source "$CONFIG_FILE"

NVME_DEV="/dev/nvme0n1"
PART_BOOT="${NVME_DEV}p1"
PART_ROOT="${NVME_DEV}p2"

MNT_BOOT="/mnt/nvme-boot-seed"
MNT_ROOT="/mnt/nvme-root-seed"

echo "=== STAGE 2: SEED NVME (OFFLINE CONFIG) ==="

# 1. Mount Partitions
echo "Mounting NVMe partitions..."
mkdir -p "$MNT_BOOT" "$MNT_ROOT"

# Unmount if already mounted
umount "$MNT_BOOT" 2>/dev/null || true
umount "$MNT_ROOT" 2>/dev/null || true
umount "${PART_BOOT}" 2>/dev/null || true
umount "${PART_ROOT}" 2>/dev/null || true

mount "$PART_BOOT" "$MNT_BOOT"
mount "$PART_ROOT" "$MNT_ROOT"

# 2. Enable SSH
echo "Enabling SSH (creating 'ssh' file in boot)..."
touch "$MNT_BOOT/ssh"

# 3. User Configuration (userconf.txt)
# Format: username:encrypted-password
echo "Configuring User: $TARGET_USER"
echo "Please enter the password for the new user ($TARGET_USER):"
read -rsp "Password: " PASSWORD
echo
PASS_HASH=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
echo "$TARGET_USER:$PASS_HASH" > "$MNT_BOOT/userconf.txt"
echo "User configuration written."

# 4. SSH Keys (authorized_keys)
# We look for *.pub files in config/keys/
KEY_FILE="$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"
mkdir -p "$MNT_ROOT/home/$TARGET_USER/.ssh"

echo "Checking for SSH keys in $KEYS_DIR..."
if ls "$KEYS_DIR"/*.pub 1> /dev/null 2>&1; then
    echo "Adding keys to authorized_keys..."
    cat "$KEYS_DIR"/*.pub >> "$KEY_FILE"
    
    # Set permissions (Critical!)
    # We need to find the UID of the user. Since it's a new image, user isn't created yet in /etc/passwd?
    # Actually, userconf.txt creates it on first boot.
    # So the /home/user dir won't exist yet!
    # WAIT. userconf.txt logic happens on first boot. The /home/user dir is created THEN.
    # We cannot write to /home/user/.ssh if /home/user doesn't exist.
    
    echo "WARNING: Since this is a fresh image, the user home directory does not exist yet."
    echo "We will seed keys to /boot/firmware/user-data if using cloud-init, or..."
    echo "Actually, standard RPi OS doesn't support pre-seeding authorized_keys easily without cloud-init."
    
    # Solution: We can create the dir, but we don't know the UID (usually 1000).
    # Let's try to create it manually.
    echo "Pre-creating home directory for SSH keys..."
	mkdir -p "$MNT_ROOT/home/$TARGET_USER/.ssh"
	chmod 700 "$MNT_ROOT/home/$TARGET_USER"
	chmod 700 "$MNT_ROOT/home/$TARGET_USER/.ssh"
	cat "$KEYS_DIR"/*.pub >> "$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"
	chmod 600 "$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"
    
    # Set ownership to 1000:1000 (Default for first user)
    chown -R 1000:1000 "$MNT_ROOT/home/$TARGET_USER"
    echo "SSH keys seeded."
else
    echo "No public keys found in $KEYS_DIR. Skipping."
fi

# 5. Wi-Fi Configuration (Pre-bookworm style, works on boot)
# NetworkManager will read this on first boot if we place it right?
# Actually, Bookworm uses NetworkManager. 'wpa_supplicant.conf' in /boot IS NOT reliably moved anymore.
# We should use 'nmcli' connection files in /etc/NetworkManager/system-connections/

if [[ -n "$WIFI_SSID" ]]; then
    echo "Seeding Wi-Fi config for NetworkManager..."
    NM_DIR="$MNT_ROOT/etc/NetworkManager/system-connections"
    mkdir -p "$NM_DIR"
    
    # Create a keyfile for the connection
    cat <<EOF > "$NM_DIR/$WIFI_SSID.nmconnection"
[connection]
id=$WIFI_SSID
type=wifi
interface-name=wlan0

[wifi]
ssid=$WIFI_SSID
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=$WIFI_PASS

[ipv4]
method=auto

[ipv6]
method=auto
EOF
    chmod 600 "$NM_DIR/$WIFI_SSID.nmconnection"
    # Ownership root:root is fine for NetworkManager config
    echo "Wi-Fi config written."
fi

# 6. Hostname
if [[ -n "$TARGET_HOSTNAME" ]]; then
    echo "Setting Hostname: $TARGET_HOSTNAME"
    echo "$TARGET_HOSTNAME" > "$MNT_ROOT/etc/hostname"
    sed -i "s/127.0.1.1.*/127.0.1.1\t$TARGET_HOSTNAME/g" "$MNT_ROOT/etc/hosts"
fi

# Cleanup
echo "Unmounting..."
sync
umount "$MNT_BOOT"
umount "$MNT_ROOT"

echo "=== SEEDING COMPLETE ==="
echo "You can now reboot into the NVMe drive."
