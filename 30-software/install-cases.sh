#!/usr/bin/env bash
set -euo pipefail

# 30-software/install-cases.sh
# Installers for specific Pi 5 Cases

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

show_menu() {
    echo
    echo "=== CASE SOFTWARE INSTALLER ==="
    echo "1) Pironman 5 Max (SunFounder)"
    echo "2) Argon One V3 / M.2 (Argon40)"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select Case: " choice
}

install_pironman() {
    echo "Installing Pironman 5 Max software..."
    echo "Dependencies..."
    apt-get update
    apt-get install -y git python3 python3-pip python3-setuptools

    TARGET_DIR="/home/$TARGET_USER/pironman5"
    if [[ -d "$TARGET_DIR" ]]; then
        echo "Removing existing pironman5 folder..."
        rm -rf "$TARGET_DIR"
    fi

    echo "Cloning repo..."
    sudo -u "$TARGET_USER" git clone -b max https://github.com/sunfounder/pironman5.git "$TARGET_DIR" --depth 1
    
    echo "Running installer..."
    cd "$TARGET_DIR"
    python3 install.py
    
    echo "Pironman 5 Max installed."
}

install_argon() {
    echo "Installing Argon One V3 software..."
    curl https://download.argon40.com/argon1.sh | bash
    echo "Argon One V3 installed."
    echo "Use 'argon-config' to configure fan speeds."
}

while true; do
    show_menu
    case "$choice" in
        1) install_pironman ;;
        2) install_argon ;;
        0) break ;;
        *) echo "Invalid option." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
done
