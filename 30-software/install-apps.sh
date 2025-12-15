#!/usr/bin/env bash
set -euo pipefail

# 30-software/install-apps.sh
# Software installation: Pi-Apps, RPi Connect, Git Repo

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

echo "=== STAGE 3: SOFTWARE INSTALLATION ==="

# Helper to run as target user
run_as_user() {
    sudo -u "$TARGET_USER" "$@"
}

# 1. Pi-Apps
if [[ "$INSTALL_PI_APPS" == "true" ]]; then
    if [[ -d "/home/$TARGET_USER/pi-apps" ]]; then
        echo "Pi-Apps already installed."
    else
        echo "Installing Pi-Apps for user $TARGET_USER..."
        # Pi-Apps install script expects to be run by the user
        run_as_user bash -c 'wget -qO- https://raw.githubusercontent.com/Botspot/pi-apps/master/install | bash'
    fi
fi

# 2. Raspberry Pi Connect
if [[ "$ENABLE_RPI_CONNECT" == "true" ]]; then
    echo "Installing Raspberry Pi Connect..."
    apt-get install -y rpi-connect
    systemctl enable --now rpi-connect
    echo "NOTE: To link this device to your ID, run 'rpi-connect signin' as $TARGET_USER."
fi

# 3. Clone Git Repo
if [[ -n "$GIT_REPO_URL" ]]; then
    REPO_NAME=$(basename "$GIT_REPO_URL" .git)
    TARGET_DIR="/home/$TARGET_USER/$REPO_NAME"
    
    if [[ -d "$TARGET_DIR" ]]; then
        echo "Repo $REPO_NAME already exists at $TARGET_DIR. Pulling latest..."
        run_as_user git -C "$TARGET_DIR" pull
    else
        echo "Cloning $GIT_REPO_URL into $TARGET_DIR..."
        run_as_user git clone "$GIT_REPO_URL" "$TARGET_DIR"
    fi
fi

echo "=== STAGE 3 COMPLETE ==="
echo "Software installed."
