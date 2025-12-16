#!/usr/bin/env bash
set -euo pipefail

# 20-configure/security-wizard.sh
# Interactive wizard for hardening system security and managing SSH keys.

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
CONFIG_FILE="$BASE_DIR/config/settings.conf"
# Load config to get TARGET_USER
if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; fi
TARGET_USER="${TARGET_USER:-$(whoami)}"

echo -e "${BLUE}=== SECURITY WIZARD ===${NC}"
echo "Target User: $TARGET_USER"
echo "This tool helps you manage SSH keys and harden system security."
read -rp "Press Enter to continue..."

# --- FUNCTIONS ---

import_github_keys() {
    echo -e "\n${YELLOW}--- Import Keys from GitHub ---${NC}"
    read -rp "Enter GitHub Username: " GH_USER
    if [[ -z "$GH_USER" ]]; then echo "Cancelled."; return; fi

    echo "Fetching keys for $GH_USER..."
    # capture output, allow curl to fail without exiting script immediately
    if ! KEYS=$(curl -s -f "https://github.com/$GH_USER.keys"); then
        echo -e "${RED}Failed to fetch keys (User not found or network error).${NC}"
        return
    fi
    
    if [[ -n "$KEYS" ]]; then
        echo -e "\n${BLUE}--- Key Preview ---${NC}"
        echo "$KEYS"
        echo -e "${BLUE}-------------------${NC}"
        
        read -rp "Do these keys look correct? Import them? (y/N): " CONFIRM
        if [[ "${CONFIRM,,}" != "y" ]]; then echo "Import cancelled."; return; fi

        USER_HOME=$(eval echo "~$TARGET_USER")
        SSH_DIR="$USER_HOME/.ssh"
        AUTH_KEYS="$SSH_DIR/authorized_keys"
        
        sudo mkdir -p "$SSH_DIR"
        sudo chmod 700 "$SSH_DIR"
        
        # Append keys
        echo "$KEYS" | sudo tee -a "$AUTH_KEYS" > /dev/null
        
        sudo chmod 600 "$AUTH_KEYS"
        sudo chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"
        echo -e "${GREEN}Keys imported successfully!${NC}"
    else
        echo -e "${RED}No keys found.${NC}"
    fi
}

import_usb_keys() {
    echo -e "\n${YELLOW}--- Import Keys from USB ---${NC}"
    echo "Please insert a USB drive containing public key files (*.pub)."
    read -rp "Press Enter when drive is inserted..."
    
    USB_DEVS=$(lsblk -o NAME,TRAN,MOUNTPOINT -rn | grep "usb" | awk '{print $1}')
    
    if [[ -z "$USB_DEVS" ]]; then
        echo -e "${RED}No USB devices detected.${NC}"
        return
    fi
    
    FOUND_KEYS=0
    MOUNT_POINT="/mnt/usb-keys-temp"
    sudo mkdir -p "$MOUNT_POINT"
    
    for DEV in $USB_DEVS; do
        DEV_PATH="/dev/$DEV"
        # Only try partitions (e.g., sda1 not sda)
        if [[ "$DEV" == *[0-9] ]]; then
            # Try to mount, continue loop if fails
            if sudo mount "$DEV_PATH" "$MOUNT_POINT" 2>/dev/null; then
                echo "Scanning $DEV_PATH..."
                
                # Use find with process substitution to handle spaces safely
                while IFS= read -r -d '' KEY_FILE; do
                    FILENAME=$(basename "$KEY_FILE")
                    echo -e "\n${BLUE}Found Key File: $FILENAME${NC}"
                    
                    read -rp "Import this key? (y/N): " CONFIRM
                    if [[ "${CONFIRM,,}" == "y" ]]; then
                        USER_HOME=$(eval echo "~$TARGET_USER")
                        SSH_DIR="$USER_HOME/.ssh"
                        AUTH_KEYS="$SSH_DIR/authorized_keys"
                        
                        sudo mkdir -p "$SSH_DIR"
                        sudo chmod 700 "$SSH_DIR"
                        
                        cat "$KEY_FILE" | sudo tee -a "$AUTH_KEYS" > /dev/null
                        sudo chmod 600 "$AUTH_KEYS"
                        sudo chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"
                        
                        echo -e "${GREEN}Imported $FILENAME${NC}"
                        FOUND_KEYS=1
                    fi
                done < <(find "$MOUNT_POINT" -maxdepth 2 -name "*.pub" -print0)
                
                sudo umount "$MOUNT_POINT"
            fi
        fi
    done
    
    if [[ $FOUND_KEYS -eq 1 ]]; then
        echo -e "${GREEN}USB Import Complete.${NC}"
    else
        echo -e "${YELLOW}No keys imported.${NC}"
    fi
}

generate_ssh_key() {
    echo -e "\n${YELLOW}--- Generate New SSH Key ---${NC}"
    USER_HOME=$(eval echo "~$TARGET_USER")
    KEY_PATH="$USER_HOME/.ssh/id_ed25519"
    
    if sudo test -f "$KEY_PATH"; then
        echo -e "${RED}Key already exists at $KEY_PATH.${NC}"
        read -rp "Overwrite? (y/N): " CONFIRM
        if [[ "${CONFIRM,,}" != "y" ]]; then return; fi
    fi
    
    echo "Generating Ed25519 key pair..."
    # Ensure .ssh dir exists
    sudo mkdir -p "$(dirname "$KEY_PATH")"
    sudo chown "$TARGET_USER:$TARGET_USER" "$(dirname "$KEY_PATH")"
    
    sudo -u "$TARGET_USER" ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "$TARGET_USER@$HOSTNAME"
    
    echo -e "${GREEN}Key generated!${NC}"
    echo "Here is your public key (add this to GitHub/GitLab):"
    echo -e "${BLUE}"
    sudo cat "$KEY_PATH.pub"
    echo -e "${NC}"
}

harden_sshd() {
    echo -e "\n${YELLOW}--- Harden SSH Configuration ---${NC}"
    SSHD_CONFIG="/etc/ssh/sshd_config"
    
    echo "1) Disable Password Authentication (Keys ONLY)"
    echo "2) Disable Root Login"
    echo "3) Apply Both"
    echo "0) Cancel"
    read -rp "Select option: " CHOICE
    
    if [[ "$CHOICE" == "0" ]]; then return; fi
    
    # SAFETY CHECK
    if [[ "$CHOICE" == "1" || "$CHOICE" == "3" ]]; then
        echo -e "\n${RED}${BOLD}CRITICAL WARNING: RISK OF LOCKOUT${NC}"
        echo "You are about to disable password authentication."
        echo "If you have not verified that your SSH keys work, you will be locked out."
        echo "Please open a NEW terminal window and verify login via key now."
        echo
        echo "Type 'LOCKED' to confirm you accept this risk:"
        read -r SAFETY_CHECK
        if [[ "$SAFETY_CHECK" != "LOCKED" ]]; then
            echo "Aborted."
            return
        fi
    fi

    case "$CHOICE" in
        1|3)
            echo "Disabling PasswordAuthentication..."
            # Ensure setting exists or is uncommented
            if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
                sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
            else
                echo "PasswordAuthentication no" | sudo tee -a "$SSHD_CONFIG" > /dev/null
            fi
            # Also handle commented out default
            sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
            ;; 
    esac
    
    case "$CHOICE" in
        2|3)
            echo "Disabling PermitRootLogin..."
            if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
                sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
            else
                echo "PermitRootLogin no" | sudo tee -a "$SSHD_CONFIG" > /dev/null
            fi
            sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
            ;; 
    esac
    
    echo "Restarting SSH service..."
    sudo systemctl restart ssh
    echo -e "${GREEN}SSH Hardening Applied.${NC}"
}

install_firewall() {
    echo -e "\n${YELLOW}--- Install Firewall (UFW) ---${NC}"
    if ! command -v ufw &>/dev/null; then
        echo "Installing UFW..."
        sudo apt-get update && sudo apt-get install -y ufw
    fi
    
    echo "Configuring UFW Defaults..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    echo "Allowing SSH (Port 22)..."
    sudo ufw allow 22/tcp
    
    echo "Enabling UFW..."
    # 'yes' to confirm disruption warning
    echo "y" | sudo ufw enable
    
    sudo ufw status verbose
    echo -e "${GREEN}Firewall enabled and secured.${NC}"
}

install_fail2ban() {
    echo -e "\n${YELLOW}--- Install Fail2Ban ---${NC}"
    echo "Fail2Ban monitors logs and bans IPs that show malicious signs."
    
    if ! command -v fail2ban-client &>/dev/null; then
        echo "Installing Fail2Ban..."
        sudo apt-get update && sudo apt-get install -y fail2ban
    fi
    
    echo "Configuring Fail2Ban for SSH..."
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    
    echo -e "${GREEN}Fail2Ban installed and running.${NC}"
    sudo systemctl enable --now fail2ban
    sudo fail2ban-client status
}

# --- MENU ---

while true; do
    echo -e "\n${BLUE}--- SECURITY MENU ---${NC}"
    echo "1) Import SSH Keys from GitHub"
    echo "2) Import SSH Keys from USB"
    echo "3) Generate New SSH Key Pair"
    echo "4) Harden SSH (Disable Passwords/Root)"
    echo "5) Install Firewall (UFW)"
    echo "6) Install Fail2Ban"
    echo "0) Return to Main Menu"
    
    read -rp "Select option: " OPT
    case "$OPT" in
        1) import_github_keys ;;
        2) import_usb_keys ;;
        3) generate_ssh_key ;;
        4) harden_sshd ;;
        5) install_firewall ;;
        6) install_fail2ban ;;
        0) exit 0 ;;
        *) echo "Invalid option." ;;
    esac
done
