#!/usr/bin/env bash
set -euo pipefail

# 20-configure/configure-live.sh
# System configuration: User, Network, Hostname. Runs on the live system.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

echo "=== STAGE 2: LIVE SYSTEM CONFIGURATION ==="

# 1. Hostname
CURRENT_HOST=$(hostname)
if [[ "$CURRENT_HOST" != "$TARGET_HOSTNAME" ]]; then
    echo "Setting hostname to $TARGET_HOSTNAME..."
    hostnamectl set-hostname "$TARGET_HOSTNAME"
    sed -i "s/127.0.1.1.*/127.0.1.1\t$TARGET_HOSTNAME/g" /etc/hosts
fi

# 2. Timezone
echo "Setting timezone to $TARGET_TIMEZONE..."
timedatectl set-timezone "$TARGET_TIMEZONE"

# 3. User Account
if id "$TARGET_USER" &>/dev/null; then
    echo "User $TARGET_USER already exists."
else
    echo "Creating user $TARGET_USER..."
    useradd -m -s /bin/bash -G sudo,video,plugdev,games,users,input,netdev,gpio,i2c,spi "$TARGET_USER"
    echo "Please set the password for $TARGET_USER:"
    passwd "$TARGET_USER"
fi

# 4. Network (Wi-Fi)
# Bookworm uses NetworkManager
if [[ -n "$WIFI_SSID" ]]; then
    echo "Configuring Wi-Fi for SSID: $WIFI_SSID..."
    # Check if connection already exists
    if nmcli con show "$WIFI_SSID" &>/dev/null; then
        echo "Wi-Fi connection already configured."
    else
        nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS" || echo "WARNING: Wi-Fi connection failed. Check credentials."
    fi
fi

# 5. SSH (if not already enabled)
if [[ "$ENABLE_SSH" == "true" ]]; then
    echo "Ensuring SSH is enabled..."
    systemctl enable --now ssh
fi

# 6. Import SSH Keys from GitHub (Optional)
read -rp "Do you want to import SSH public keys from GitHub? (y/N): " IMPORT_GH_KEYS
if [[ "${IMPORT_GH_KEYS,,}" == "y" ]]; then
    read -rp "Enter GitHub Username: " GH_USERNAME
    if [[ -n "$GH_USERNAME" ]]; then
        echo "Fetching keys for $GH_USERNAME..."
        GH_KEYS=$(curl -s "https://github.com/$GH_USERNAME.keys")
        if [[ -n "$GH_KEYS" ]]; then
            # Ensure ~/.ssh exists and has correct permissions
            USER_SSH_DIR="/home/$TARGET_USER/.ssh"
            mkdir -p "$USER_SSH_DIR"
            chmod 700 "$USER_SSH_DIR"
            
            # Append keys and set permissions
            echo "$GH_KEYS" >> "$USER_SSH_DIR/authorized_keys"
            chmod 600 "$USER_SSH_DIR/authorized_keys"
            chown -R "$TARGET_USER:$TARGET_USER" "$USER_SSH_DIR"
            
            echo "SSH keys for $GH_USERNAME imported successfully."
        else
            echo "WARNING: No SSH keys found for $GH_USERNAME on GitHub or failed to fetch."
        fi
    else
        echo "Skipping GitHub SSH key import (no username provided)."
    fi
fi

# 7. Basic Updates
echo "Running basic system update..."
apt-get update

echo "=== STAGE 2: LIVE CONFIGURATION COMPLETE ==="
echo "System is configured. You may need to reboot for hostname changes to fully apply or for SSH/Wi-Fi to stabilize."
