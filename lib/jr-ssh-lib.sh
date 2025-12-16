#!/usr/bin/env bash
#
# jr-ssh-lib.sh
# Library functions for the JR SSH Wizard.
# This script is intended to be sourced by jr-ssh-wizard.sh
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

# --- Color Codes ---
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;34m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m' # No Color

# --- Globals (Defined in main script, but used here) ---
# For shellcheck to not complain about sourced variables
# shellcheck disable=SC2154
: "${TOOLKIT_BASE_DIR?}"
: "${LIB_DIR?}"
: "${BACKUP_BASE_DIR?}"
: "${LOG_BASE_DIR?}"
: "${SSH_LOG_FILE?}"
: "${SSHD_CONF_D_DIR?}"
: "${SSHD_HARDENING_CONF?}"
: "${TARGET_USER?}"

# --- Derived Paths ---
TARGET_USER_HOME=$(eval echo "~${TARGET_USER}")
AUTH_KEYS_DIR="${TARGET_USER_HOME}/.ssh"
AUTH_KEYS_FILE="${AUTH_KEYS_DIR}/authorized_keys"

# --- Logging ---
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}" | sudo tee -a "${SSH_LOG_FILE}" > /dev/null
}

# --- UI Helpers ---
prompt_yn() {
    local prompt_msg="$1"
    local default_yes="${2:-true}" # true for Yes as default, false for No
    local response
    
    if "${default_yes}"; then
        read -rp "${prompt_msg} (Y/n): " response
        [[ "${response}" =~ ^[Yy]$|^$ ]]
    else
        read -rp "${prompt_msg} (y/N): " response
        [[ "${response}" =~ ^[Yy]$ ]]
    fi
}

display_message() {
    local type="$1" # INFO, WARNING, ERROR
    local message="$2"
    case "$type" in
        INFO) echo -e "${BLUE}${message}${NC}" ;; 
        WARNING) echo -e "${YELLOW}WARNING: ${message}${NC}" ;; 
        ERROR) echo -e "${RED}ERROR: ${message}${NC}" ; log_message "ERROR: ${message}" ;; 
        SUCCESS) echo -e "${GREEN}SUCCESS: ${message}${NC}" ;; 
        *) echo "${message}" ;; 
    esac
}

# --- Core Helpers ---
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        display_message ERROR "This script must be run as root. Please use 'sudo'."
        exit 1
    fi
}

# Safely write content to a file using a temporary file and atomic move
safe_write_file() {
    local file_path="$1"
    local content="$2"
    local perms="${3:-644}" # Default permissions
    local owner="${4:-root:root}" # Default owner

    log_message "Attempting to safely write to ${file_path}"
    local tmp_file
    tmp_file=$(mktemp "${file_path}.XXXXXX")

    echo "${content}" > "${tmp_file}"
    sudo chown "${owner}" "${tmp_file}"
    sudo chmod "${perms}" "${tmp_file}"
    sudo mv -T "${tmp_file}" "${file_path}"
    log_message "Successfully wrote to ${file_path}"
}

# --- Backup/Restore Functions ---
backup_file() {
    local file_to_backup="$1"
    local backup_dir="$2"
    
    if [[ ! -f "${file_to_backup}" ]]; then
        log_message "No file to backup: ${file_to_backup}"
        return 0 # Not an error if file doesn't exist
    fi

    sudo mkdir -p "${backup_dir}"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="${backup_dir}/$(basename "${file_to_backup}").${timestamp}.bak"
    
    log_message "Backing up ${file_to_backup} to ${backup_path}"
    sudo cp -p "${file_to_backup}" "${backup_path}"
    if [[ $? -eq 0 ]]; then
        display_message SUCCESS "Backup created: $(basename "${backup_path}")"
        return 0
    else
        display_message ERROR "Failed to create backup for ${file_to_backup}"
        return 1
    fi
}

restore_menu() {
    local original_file="$1"
    local backup_dir="$2"

    display_message INFO "Available backups for ${original_file}"
    local backups
    # Using `find` to get full paths and handle spaces
    mapfile -t backups < <(sudo find "${backup_dir}" -maxdepth 1 -type f -name "$(basename "${original_file}").*.bak" -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2-)
    
    if [[ "${#backups[@]}" -eq 0 ]]; then
        display_message WARNING "No backups found in ${backup_dir}"
        return
    fi
    
    local i=1
    for backup_path in "${backups[@]}"; do
        local filename
        filename=$(basename "${backup_path}")
        local timestamp_str
        timestamp_str=$(echo "${filename}" | sed -n 's/.*\.bak\.\([0-9]\\{8\\}_[0-9]\\{6\\}\\)\.bak/\1/p')
        local human_date
        human_date=$(date -d "${timestamp_str:0:8} ${timestamp_str:9:6}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "${timestamp_str}")
        echo "  ${i}) ${human_date} - ${filename}"
        i=$((i+1))
    done
    
    local choice
    read -rp "Enter number of backup to restore, or 0 to cancel: " choice
    
    if [[ "${choice}" -eq 0 ]]; then
        display_message INFO "Restore cancelled."
        return
    fi
    
    if [[ "${choice}" -ge 1 && "${choice}" -le "${#backups[@]}" ]]; then
        local selected_backup="${backups[$((choice-1))]}"
        if prompt_yn "Are you sure you want to restore '${selected_backup}' to '${original_file}'?"; then
            log_message "Restoring ${selected_backup} to ${original_file}"
            sudo cp "${selected_backup}" "${original_file}"
            display_message SUCCESS "Successfully restored ${original_file}"
        else
            display_message INFO "Restore cancelled."
        fi
    else
        display_message ERROR "Invalid choice."
    fi
}

backup_restore_menu() {
    local choice
    while true; do
        clear
        log_message "Displaying backup/restore menu."
        echo -e "${BLUE}=== BACKUP / RESTORE ===${NC}"
        echo -e "${YELLOW}  1) Backup SSHD Config${NC}"
        echo -e "${YELLOW}  2) Restore SSHD Config${NC}"
        echo -e "${YELLOW}  3) Backup Authorized Keys${NC}"
        echo -e "${YELLOW}  4) Restore Authorized Keys${NC}"
        echo -e "${YELLOW}  0) Return to Main Menu${NC}"
        echo -e "${BLUE}-----------------------"${NC}"
        read -rp "Enter your choice: " choice

        case "${choice}" in
            1) backup_file "/etc/ssh/sshd_config" "${BACKUP_BASE_DIR}/sshd_config" ;; 
            2) restore_menu "/etc/ssh/sshd_config" "${BACKUP_BASE_DIR}/sshd_config" ;; 
            3) backup_file "${AUTH_KEYS_FILE}" "${BACKUP_BASE_DIR}/authorized_keys" ;; 
            4) restore_menu "${AUTH_KEYS_FILE}" "${BACKUP_BASE_DIR}/authorized_keys" ;; 
            0) return ;; 
            *) display_message ERROR "Invalid option." ;; 
        esac
        read -rp "Press Enter to continue..."
    done
}


# --- Authorized Keys Management ---

# Extract the base64 blob part of a public key string
get_key_blob() {
    local key_string="$1"
    # Match ssh-rsa, ssh-ed25519, ecdsa-sha2-nistp256, then capture the base64 part
    echo "${key_string}" | grep -oE '(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256) +([A-Za-z0-9+/=]+)' | awk '{print $2}'
}

# Check if a key (by its blob) already exists in authorized_keys
is_duplicate_key() {
    local new_key_string="$1"
    local new_blob
    new_blob=$(get_key_blob "${new_key_string}")

    if [[ -z "${new_blob}" ]]; then
        return 1 # Invalid key string, not a duplicate
    fi

    # Iterate through each key in authorized_keys and check its blob
    if [[ -f "${AUTH_KEYS_FILE}" ]]; then
        while IFS= read -r line; do
            local existing_blob
            existing_blob=$(get_key_blob "${line}")
            if [[ "${existing_blob}" == "${new_blob}" ]]; then
                return 0 # Found a duplicate
            fi
        done < <(sudo cat "${AUTH_KEYS_FILE}" 2>/dev/null)
    fi
    return 1 # Not a duplicate
}


fix_authorized_keys_perms() {
    log_message "Fixing permissions for ${AUTH_KEYS_DIR}"
    sudo mkdir -p "${AUTH_KEYS_DIR}"
    sudo chown "${TARGET_USER}:${TARGET_USER}" "${AUTH_KEYS_DIR}"
    sudo chmod 700 "${AUTH_KEYS_DIR}"

    if [[ -f "${AUTH_KEYS_FILE}" ]]; then
        sudo chown "${TARGET_USER}:${TARGET_USER}" "${AUTH_KEYS_FILE}"
        sudo chmod 600 "${AUTH_KEYS_FILE}"
        display_message SUCCESS "Permissions for ${AUTH_KEYS_DIR} and ${AUTH_KEYS_FILE} fixed."
    else
        display_message WARNING "${AUTH_KEYS_FILE} not found. Directory permissions fixed."
    fi
}

add_authorized_key() {
    local key_string="$1"
    log_message "Attempting to add SSH key to ${AUTH_KEYS_FILE}"

    if ! echo "${key_string}" | grep -qE '^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256) +[A-Za-z0-9+/=]+'; then
        display_message ERROR "Invalid public key format. Must start with ssh-rsa, ssh-ed25519, or ecdsa-sha2-nistp256."
        return 1
    fi

    fix_authorized_keys_perms # Ensure directory/file exist with correct perms

    if is_duplicate_key "${key_string}"; then
        display_message WARNING "Key already exists (duplicate base64 blob). Skipping."
        return 0
    fi
    
    # Append key using sudo tee for atomic write
    echo "${key_string}" | sudo tee -a "${AUTH_KEYS_FILE}" > /dev/null
    display_message SUCCESS "Key added to ${AUTH_KEYS_FILE}"
    return 0
}

list_authorized_keys() {
    log_message "Listing authorized keys."
    clear
    echo -e "${BLUE}=== LIST AUTHORIZED KEYS for ${TARGET_USER} ===${NC}"
    fix_authorized_keys_perms # Ensure perms are good before listing

    if [[ ! -f "${AUTH_KEYS_FILE}" || ! -s "${AUTH_KEYS_FILE}" ]]; then
        display_message INFO "No authorized keys found for ${TARGET_USER}"
        return 0
    fi

    local keys_array=()
    local i=1
    
    # Read keys line by line, handling potential options before key type
    while IFS= read -r line; do
        if [[ -n "${line}" ]]; then # Ignore empty lines
            # Get fingerprint, suppressing errors for invalid lines
            local fingerprint
            # Use a temporary file for ssh-keygen input to avoid breaking set -e
            local tmp_key_file
            tmp_key_file=$(mktemp)
            echo "${line}" > "${tmp_key_file}"
            fingerprint=$(ssh-keygen -lf "${tmp_key_file}" 2>/dev/null | awk '{print $2 " " $3}')
            rm "${tmp_key_file}"

            if [[ -n "${fingerprint}" ]]; then
                echo "  ${i}) ${fingerprint}"
                keys_array+=("${line}") # Store original line for removal
                i=$((i+1))
            else
                echo "  ${i}) (Invalid/Unparseable Key) ${line}" # Show problematic lines too
                keys_array+=("${line}")
                i=$((i+1))
            fi
        fi
    done < <(sudo cat "${AUTH_KEYS_FILE}" 2>/dev/null)
    echo -e "${BLUE}----------------------------------------${NC}"
    # Store keys_array in a global temp variable or return it if needed for removal
    # For now, just display.
    # To use keys_array for removal, it needs to be returned or passed.
    printf '%s\n' "${keys_array[@]}" > "${TOOLKIT_BASE_DIR}/.keys_list_cache"
    return 0
}

remove_authorized_key() {
    log_message "Attempting to remove authorized key."
    list_authorized_keys # Displays keys and caches them to .keys_list_cache

    local keys_array=()
    mapfile -t keys_array < "${TOOLKIT_BASE_DIR}/.keys_list_cache"
    
    if [[ "${#keys_array[@]}" -eq 0 ]]; then
        display_message WARNING "No keys to remove."
        return
    fi
    
    local choice
    read -rp "Enter number of key to remove, or 0 to cancel: " choice
    
    if [[ "${choice}" -eq 0 ]]; then
        display_message INFO "Removal cancelled."
        return
    fi
    
    if [[ "${choice}" -ge 1 && "${choice}" -le "${#keys_array[@]}" ]]; then
        if prompt_yn "Are you sure you want to remove this key?"; then
            local key_to_remove="${keys_array[$((choice-1))]}"
            log_message "Removing key: ${key_to_remove}"
            
            # Use sed to remove the exact line, ensuring backup first
            backup_file "${AUTH_KEYS_FILE}" "${BACKUP_BASE_DIR}/authorized_keys"
            # Use temp file for atomic replace
            local tmp_file
            tmp_file=$(mktemp)
            sudo grep -vF "${key_to_remove}" "${AUTH_KEYS_FILE}" > "${tmp_file}"
            sudo mv -T "${tmp_file}" "${AUTH_KEYS_FILE}"
            fix_authorized_keys_perms # Fix perms after move
            display_message SUCCESS "Key removed."
        else
            display_message INFO "Removal cancelled."
        fi
    else
        display_message ERROR "Invalid choice."
    fi
}

# Menu for managing authorized_keys
manage_authorized_keys_menu() {
    local choice
    while true; do
        clear
        log_message "Displaying authorized keys management menu."
        echo -e "${BLUE}=== MANAGE AUTHORIZED KEYS ===${NC}"
        echo -e "${YELLOW}  1) List Authorized Keys & Fingerprints${NC}"
        echo -e "${YELLOW}  2) Add Public Key (Paste Manually)${NC}"
        echo -e "${YELLOW}  3) Remove Public Key${NC}"
        echo -e "${YELLOW}  4) Replace ALL Authorized Keys${NC}"
        echo -e "${YELLOW}  5) Fix Permissions${NC}"
        echo -e "${YELLOW}  0) Return to Main Menu${NC}"
        echo -e "${BLUE}------------------------------${NC}"
        read -rp "Enter your choice: " choice

        case "${choice}" in
            1) list_authorized_keys ;; 
            2) 
                echo -e "${BLUE}Paste the public key you want to add and press Enter (Ctrl+D to finish, or just Enter for one line):${NC}"
                local key_input=""
                # Read multiple lines until EOF or empty line
                while IFS= read -r line; do
                    [[ -z "${line}" ]] && break # Break on empty line
                    key_input+="${line}\n"
                done
                key_input=$(echo -e "${key_input}" | sed '$d') # Remove trailing newline from last line
                add_authorized_key "${key_input}"
                ;; 
            3) remove_authorized_key ;; 
            4) # Replace ALL keys logic
                display_message WARNING "This will remove ALL existing keys and add a new one."
                if prompt_yn "Are you sure you want to replace ALL keys?"; then
                    echo -e "${BLUE}Paste the SINGLE public key to use for ALL authorized keys:${NC}"
                    local new_key=""
                    read -r new_key
                    if [[ -n "${new_key}" ]]; then
                        backup_file "${AUTH_KEYS_FILE}" "${BACKUP_BASE_DIR}/authorized_keys"
                        echo "${new_key}" | sudo tee "${AUTH_KEYS_FILE}" > /dev/null
                        fix_authorized_keys_perms
                        display_message SUCCESS "Authorized keys replaced with new key."
                    else
                        display_message ERROR "No key provided. Operation cancelled."
                    fi
                else
                    display_message INFO "Replacement cancelled."
                fi
                ;; 
            5) fix_authorized_keys_perms ;; 
            0) return ;; 
            *) display_message ERROR "Invalid option." ;; 
        esac
        read -rp "Press Enter to continue..."
    done
}


# --- SSHD Hardening ---

validate_sshd_config() {
    log_message "Validating SSHD config."
    # sshd -t returns non-zero on error and prints to stderr
    if sudo sshd -t -f "/etc/ssh/sshd_config" -f "${SSHD_HARDENING_CONF}" &>/dev/null; then
        display_message SUCCESS "SSHD configuration is valid."
        return 0
    else
        display_message ERROR "SSHD configuration is NOT valid. Check logs for details."
        return 1
    fi
}

reload_sshd() {
    log_message "Attempting to reload SSHD service."
    if validate_sshd_config; then
        sudo systemctl reload sshd
        if [[ $? -eq 0 ]]; then
            display_message SUCCESS "SSHD service reloaded successfully."
            return 0
        else
            display_message ERROR "Failed to reload SSHD service."
            return 1
        fi
    else
        display_message ERROR "SSHD config is invalid. Not reloading service."
        return 1
    fi
}

configure_sshd_hardening() {
    local mode="$1" # 'enable', 'disable', 'undo'
    log_message "Configuring SSHD hardening: ${mode}"

    backup_file "/etc/ssh/sshd_config" "${BACKUP_BASE_DIR}/sshd_config"
    backup_file "${SSHD_HARDENING_CONF}" "${BACKUP_BASE_DIR}/sshd_config_d" # Backup individual file

    local config_content=""

    case "${mode}" in
        enable)
            display_message WARNING "Enabling hardening will restrict SSH access."
            display_message WARNING "Ensure you have tested key-based login before proceeding."
            if ! prompt_yn "Proceed to apply hardening settings?"; then
                display_message INFO "Hardening cancelled."
                return
            fi
            
            log_message "Generating hardening config for ${SSHD_HARDENING_CONF}"
            config_content+="\n# JR SSH Toolkit Hardening Configuration\n"
            
            # Disable PasswordAuthentication - CRITICAL SAFETY
            display_message WARNING "Disabling password authentication means you MUST use SSH keys."
            display_message WARNING "If you lose your keys, you risk being LOCKED OUT."
            if prompt_yn "Disable PasswordAuthentication?"; then
                log_message "PasswordAuthentication set to no."
                config_content+="PasswordAuthentication no\n"
            else
                log_message "PasswordAuthentication not changed."
                config_content+="PasswordAuthentication yes\n" # Explicitly enable if not disabling
            fi

            # Disable PermitRootLogin
            if prompt_yn "Disable PermitRootLogin?"; then
                log_message "PermitRootLogin set to no."
                config_content+="PermitRootLogin no\n"
            else
                log_message "PermitRootLogin not changed."
                config_content+="PermitRootLogin yes\n" # Explicitly enable if not disabling
            fi

            # AllowUsers jr
            if prompt_yn "Restrict access to only user '${TARGET_USER}'?"; then
                log_message "AllowUsers set to ${TARGET_USER}"
                config_content+="AllowUsers ${TARGET_USER}\n"
            else
                log_message "AllowUsers not changed."
            fi
            
            sudo mkdir -p "${SSHD_CONF_D_DIR}"
            safe_write_file "${SSHD_HARDENING_CONF}" "${config_content}" 644 "root:root"
            reload_sshd
            ;;

        disable)
            display_message INFO "Disabling hardening means removing ${SSHD_HARDENING_CONF}"
            if prompt_yn "Are you sure you want to disable hardening (remove toolkit conf)?"; then
                log_message "Removing ${SSHD_HARDENING_CONF}"
                sudo rm -f "${SSHD_HARDENING_CONF}"
                display_message SUCCESS "Hardening configuration removed."
                reload_sshd
            else
                display_message INFO "Disabling hardening cancelled."
            fi
            ;;

        undo)
            # This is essentially 'disable' but maybe a different prompt?
            display_message WARNING "This will remove the toolkit's SSHD hardening configuration."
            if prompt_yn "Are you sure you want to undo toolkit changes?"; then
                log_message "Undoing toolkit changes by removing ${SSHD_HARDENING_CONF}"
                sudo rm -f "${SSHD_HARDENING_CONF}"
                display_message SUCCESS "Toolkit SSHD hardening undone."
                reload_sshd
            else
                display_message INFO "Undo cancelled."
            fi
            ;; 
        *)
            display_message ERROR "Invalid mode for configure_sshd_hardening: ${mode}"
            return 1
            ;; 
    esac
}

harden_sshd_menu() {
    local choice
    while true; do
        clear
        log_message "Displaying SSHD hardening menu."
        echo -e "${BLUE}=== HARDEN SSH SERVER ===${NC}"
        echo -e "${YELLOW}  1) Apply Hardening Settings${NC}"
        echo -e "${YELLOW}  2) Remove Hardening Settings${NC}"
        echo -e "${YELLOW}  0) Return to Main Menu${NC}"
        echo -e "${BLUE}-----------------------"${NC}"
        read -rp "Enter your choice: " choice

        case "${choice}" in
            1) configure_sshd_hardening "enable" ;; 
            2) configure_sshd_hardening "disable" ;; # disable or undo? disable seems clearer
            0) return ;; 
            *) display_message ERROR "Invalid option." ;; 
        esac
        read -rp "Press Enter to continue..."
    done
}


# --- Status & Diagnostics ---
show_ssh_service_status() {
    log_message "Showing SSH service status."
    echo -e "${BLUE}=== SSH SERVICE STATUS ===${NC}"
    sudo systemctl status sshd --no-pager
    echo -e "${BLUE}--------------------------${NC}"
}

show_sshd_auth_settings() {
    log_message "Showing SSHD authentication settings."
    echo -e "${BLUE}=== SSHD AUTHENTICATION SETTINGS ===${NC}"
    display_message INFO "Note: Settings shown are effective (may be overridden by earlier files)."
    # sshd -T shows effective config, requires sudo
    sudo sshd -T | grep -E '^(passwordauthentication|permitrootlogin|allowusers|authenticationmethods)' || true
    echo -e "${BLUE}------------------------------------${NC}"
}

show_status_diagnostics() {
    local choice
    while true; do
        clear
        log_message "Displaying status and diagnostics menu."
        echo -e "${BLUE}=== STATUS & DIAGNOSTICS ===${NC}"
        echo -e "${YELLOW}  1) SSH Service Status${NC}"
        echo -e "${YELLOW}  2) SSHD Auth Settings${NC}"
        echo -e "${YELLOW}  3) List Authorized Keys Fingerprints${NC}"
        echo -e "${YELLOW}  0) Return to Main Menu${NC}"
        echo -e "${BLUE}--------------------------${NC}"
        read -rp "Enter your choice: " choice

        case "${choice}" in
            1) show_ssh_service_status ;; 
            2) show_sshd_auth_settings ;; 
            3) list_authorized_keys ;; # Re-use list_authorized_keys function
            0) return ;; 
            *) display_message ERROR "Invalid option." ;; 
        esac
        read -rp "Press Enter to continue..."
    done
}

# --- Fix "Too many authentication failures" ---
show_auth_failure_fix() {
    log_message "Showing fix for 'Too many authentication failures'."
    clear
    echo -e "${BLUE}=== FIX 'TOO MANY AUTHENTICATION FAILURES' ===${NC}"
    display_message INFO "This error often occurs when your SSH client tries too many keys."
    echo -e "\n${YELLOW}Recommended solution for Windows (PowerShell):${NC}"
    echo -e "  To prevent your client from sending too many keys, you can disable ssh-agent"
    echo "  forwarding for a session or explicitly tell it which key to use."
    echo -e "${BOLD}1. Disable ssh-agent for a session:${NC}"
    echo "     $env:SSH_AUTH_SOCK=\"""
    echo "     ssh user@host"
    echo -e "${BOLD}2. Specify key explicitly (recommended for persistent fix):${NC}"
    echo "     ssh -i C:\\Users\\jr\\.ssh\\id_rsa user@host"
    echo "     # OR add to your SSH config (recommended for automation)"
    echo -e "\n${YELLOW}Recommended solution for SSH Config (e.g., C:\\Users\\jr\\.ssh\\config or ~/.ssh/config):${NC}"
    echo "  Add the following snippet to your client's SSH config file:"
    echo -e "${BOLD}```${NC}"
    echo "  Host my_pi_alias"
    echo "      Hostname your_pi_ip_or_hostname"
    echo "      User jr"
    echo "      IdentitiesOnly yes"
    echo "      IdentityFile ~/.ssh/id_rsa"
    echo "      # Or IdentityFile C:\\Users\\jr\\.ssh\\id_rsa for Windows"
    echo -e "${BOLD}```${NC}"
    echo -e "\n${BLUE}------------------------------------------------${NC}"
    display_message INFO "This tells your client to only use the specified key."
}
