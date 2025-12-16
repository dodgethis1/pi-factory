#!/usr/bin/env bash
set -euo pipefail

# 20-configure/seed-nvme.sh
# "Offline" configuration for the NVMe drive.
# run this from the Golden SD to prep the NVMe for its first boot.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
KEYS_DIR="$BASE_DIR/config/keys"
source "$CONFIG_FILE"

NVME_DEV="/dev/nvme0n1"
PART_BOOT="${NVME_DEV}p1"
PART_ROOT="${NVME_DEV}p2"

MNT_BOOT="/mnt/nvme-boot-seed"
MNT_ROOT="/mnt/nvme-root-seed"

echo -e "${BLUE}=== STAGE 2: SEED NVME (OFFLINE CONFIG) ===${NC}"

# --- SAFETY CHECK ---
if [[ ! -b "$NVME_DEV" ]]; then
    echo -e "${RED}ERROR: NVMe drive not found at $NVME_DEV.${NC}"
    exit 1
fi

MODEL=$(lsblk -no MODEL "$NVME_DEV" | head -n1)
SIZE_HUMAN=$(lsblk -no SIZE "$NVME_DEV" | head -n1)

echo -e "\n${YELLOW}Target Drive Details:${NC}"
echo "   Device: $NVME_DEV"
echo "   Model:  $MODEL"
echo "   Size:   $SIZE_HUMAN"
echo
echo "This tool will configure the User, Network, and SSH on the above drive."
echo "It modifies files directly on the filesystem."
read -rp "Proceed with seeding configuration? (y/N): " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then echo "Aborted."; exit 0; fi

# 1. Mount Partitions
echo -e "\n${YELLOW}--- Mounting Partitions ---${NC}"
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
echo -e "\n${YELLOW}--- User Configuration ---${NC}"
echo "Configuring initial user: $TARGET_USER"
echo "Please set the password for the FIRST BOOT of the NVMe system."
read -rsp "Enter new password for $TARGET_USER: " PASSWORD
echo
PASS_HASH=$(echo "$PASSWORD" | openssl passwd -6 -stdin)
echo "$TARGET_USER:$PASS_HASH" > "$MNT_BOOT/userconf.txt"
echo "User credentials written to userconf.txt."

# 4. SSH Keys (authorized_keys)
echo -e "\n${YELLOW}--- Seeding SSH Keys ---${NC}"
KEY_FILE="$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"

if ls "$KEYS_DIR"/*.pub 1> /dev/null 2>&1; then
    echo "Found keys in $KEYS_DIR."
    echo "Pre-creating home directory structure..."
    
    mkdir -p "$MNT_ROOT/home/$TARGET_USER/.ssh"
    chmod 700 "$MNT_ROOT/home/$TARGET_USER"
    chmod 700 "$MNT_ROOT/home/$TARGET_USER/.ssh"
    
    cat "$KEYS_DIR"/*.pub >> "$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"
    chmod 600 "$MNT_ROOT/home/$TARGET_USER/.ssh/authorized_keys"
    
    # Set ownership to 1000:1000 (Default for first Pi user)
    chown -R 1000:1000 "$MNT_ROOT/home/$TARGET_USER"
    echo -e "${GREEN}SSH keys seeded successfully.${NC}"
else
    echo "No public keys found in $KEYS_DIR. Skipping."
fi

# 5. Wi-Fi Configuration
if [[ -n "$WIFI_SSID" ]]; then
    echo -e "\n${YELLOW}--- Seeding Wi-Fi ---${NC}"
    echo "SSID: $WIFI_SSID"
    NM_DIR="$MNT_ROOT/etc/NetworkManager/system-connections"
    mkdir -p "$NM_DIR"
    
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
    echo "Wi-Fi config written to NetworkManager."
fi

# 6. Hostname
if [[ -n "$TARGET_HOSTNAME" ]]; then
    echo -e "\n${YELLOW}--- Setting Hostname ---${NC}"
    echo "Hostname: $TARGET_HOSTNAME"
    echo "$TARGET_HOSTNAME" > "$MNT_ROOT/etc/hostname"
    sed -i "s/127.0.1.1.*/127.0.1.1\t$TARGET_HOSTNAME/g" "$MNT_ROOT/etc/hosts"
fi

# Cleanup
echo -e "\n${YELLOW}--- Finalizing ---${NC}"
sync
umount "$MNT_BOOT"
umount "$MNT_ROOT"

echo -e "${GREEN}=== SEEDING COMPLETE ===${NC}"
echo "The NVMe drive is configured."
echo "You can now reboot into the NVMe drive."