#!/usr/bin/env bash
#
# jr-ssh-wizard.sh
# Main script for the JR SSH Wizard, an interactive tool for managing SSH keys
# and hardening OpenSSH server on Raspberry Pi OS.
#
# Target environment: Raspberry Pi OS
# Install location: /opt/jr-pi-toolkit/
#
# This script requires root privileges to operate.

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully.
set -euo pipefail

# --- Configuration for Target Environment (Raspberry Pi OS) ---
declare -r TOOLKIT_BASE_DIR="/opt/jr-pi-toolkit"
declare -r LIB_DIR="${TOOLKIT_BASE_DIR}/lib"
declare -r BACKUP_BASE_DIR="/var/backups/jr-toolkit/ssh"
declare -r LOG_BASE_DIR="/var/log/jr-toolkit"
declare -r SSH_LOG_FILE="${LOG_BASE_DIR}/ssh-wizard.log"
declare -r SSHD_CONF_D_DIR="/etc/ssh/sshd_config.d"
declare -r SSHD_HARDENING_CONF="${SSHD_CONF_D_DIR}/99-jr-toolkit.conf"
declare -r TARGET_USER="jr" # The user for whom SSH keys are managed

# --- Source Library Functions ---
# Ensure the library exists before sourcing
if [[ ! -f "${LIB_DIR}/jr-ssh-lib.sh" ]]; then
    echo "ERROR: Library not found at ${LIB_DIR}/jr-ssh-lib.sh"
    echo "Please ensure the toolkit is installed correctly."
    exit 1
fi
# shellcheck source=lib/jr-ssh-lib.sh
source "${LIB_DIR}/jr-ssh-lib.sh"

# --- Main Script Logic ---

# Ensure script is run as root
check_root

# Ensure log directory exists
sudo mkdir -p "${LOG_BASE_DIR}"

# --- Main Menu ---
main_menu() {
    local choice
    while true; do
        clear
        log_message "Displaying main menu."
        echo -e "${BLUE}=== JR SSH WIZARD ===${NC}"
        echo "Toolkit Location: ${TOOLKIT_BASE_DIR}"
        echo "Target User: ${TARGET_USER}"
        echo -e "${BLUE}-----------------------${NC}"
        echo -e "${YELLOW}  1) Status & Diagnostics${NC}"
        echo -e "${YELLOW}  2) Manage Authorized Keys for '${TARGET_USER}'${NC}"
        echo -e "${YELLOW}  3) Harden SSH Server (sshd)${NC}"
        echo -e "${YELLOW}  4) Fix 'Too many authentication failures'${NC}"
        echo -e "${YELLOW}  5) Backup / Restore Configuration${NC}"
        echo -e "${YELLOW}  0) Exit${NC}"
        echo -e "${BLUE}-----------------------${NC}"
        read -rp "Enter your choice: " choice
        
        case "${choice}" in
            1) show_status_diagnostics ;;
            2) manage_authorized_keys_menu ;;
            3) harden_sshd_menu ;;
            4) show_auth_failure_fix ;;
            5) backup_restore_menu ;;
            0)
                log_message "Exiting JR SSH Wizard."
                echo -e "${GREEN}Exiting. Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
        read -rp "Press Enter to continue..."
    done
}

# --- Call Main Menu ---
main_menu
