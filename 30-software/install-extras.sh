#!/usr/bin/env bash
set -euo pipefail

# 30-software/install-extras.sh
# Installers for useful extra tools

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
source "$CONFIG_FILE"

show_menu() {
    echo
    echo "=== USEFUL EXTRAS ==="
    echo "1) Docker (Container Engine)"
    echo "2) Tailscale (Easy VPN)"
    echo "3) Cockpit (Web Dashboard)"
    echo "4) Btop (System Monitor)"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select Tool: " choice
}

install_docker() {
    if command -v docker &>/dev/null; then
        echo "Docker is already installed."
    else
        echo "Installing Docker..."
        curl -sSL https://get.docker.com | sh
        echo "Adding $TARGET_USER to docker group..."
        usermod -aG docker "$TARGET_USER"
        echo "Docker installed. User needs to re-login."
    fi
}

install_tailscale() {
    if command -v tailscale &>/dev/null; then
        echo "Tailscale is already installed."
    else
        echo "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
        echo "Tailscale installed. Run 'sudo tailscale up' to connect."
    fi
}

install_cockpit() {
    echo "Installing Cockpit..."
    apt-get install -y cockpit
    systemctl enable --now cockpit
    echo "Cockpit installed. Access at http://$(hostname -I | awk '{print $1}'):9090"
}

install_btop() {
    echo "Installing Btop..."
    apt-get install -y btop
    echo "Btop installed."
}

while true; do
    show_menu
    case "$choice" in
        1) install_docker ;;
        2) install_tailscale ;;
        3) install_cockpit ;;
        4) install_btop ;;
        0) break ;;
        *) echo "Invalid option." ;;
    esac
    echo
    read -rp "Press Enter to continue..." _
done
