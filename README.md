# JR Pi-Toolkit: SSH Wizard

This repository contains the **JR SSH Wizard**, a Bash-scripted toolkit designed to simplify SSH key management and harden the OpenSSH server specifically for Raspberry Pi OS environments. It aims to make setting up secure SSH access for user 'jr' foolproof.

## 🚀 Features

*   **Interactive Menu:** User-friendly menu for all operations.
*   **Comprehensive Diagnostics:** Check SSH service status, effective SSHD authentication settings, and list authorized keys with fingerprints.
*   **Authorized Keys Management:**
    *   List, add, remove, and replace SSH public keys for user 'jr'.
    *   Fixes file and directory permissions automatically.
    *   Detects duplicate keys to prevent clutter.
*   **SSHD Hardening:**
    *   Safely disable password authentication (with critical lockout warnings).
    *   Disable root login.
    *   Restrict SSH access to specific users (e.g., 'jr').
    *   Manages changes via `/etc/ssh/sshd_config.d/99-jr-toolkit.conf` for clean configuration.
*   **Problem Solver:** Provides instructions to fix the common "Too many authentication failures" error.
*   **Robust Backup & Restore:** Automatically backs up `sshd_config` and `authorized_keys` before making changes, with a menu to restore previous versions.
*   **Logging:** All actions are logged to `/var/log/jr-toolkit/ssh-wizard.log`.

## 🛠️ Installation & Usage

**Target Environment:** Raspberry Pi OS

**1. Clone the Repository:**

First, ensure `git` is installed on your Raspberry Pi:
```bash
sudo apt update
sudo apt install -y git
```
Then, clone the toolkit to the recommended location:
```bash
sudo git clone https://github.com/dodgethis1/jr-pi-toolkit.git /opt/jr-pi-toolkit
```

**2. Make Executable:**

Ensure the main script is executable:
```bash
sudo chmod +x /opt/jr-pi-toolkit/jr-ssh-wizard.sh
sudo chmod +x /opt/jr-pi-toolkit/lib/jr-ssh-lib.sh # Library also executable (good practice)
```

**3. Run the Wizard:**

Execute the main script with `sudo`:
```bash
sudo /opt/jr-pi-toolkit/jr-ssh-wizard.sh
```

**4. Follow the Menu:**

The wizard will present an interactive menu. Select options to view status, manage keys, or harden your SSH server.

## 📁 File Structure

```
/opt/jr-pi-toolkit/
├── jr-ssh-wizard.sh      # Main executable script
└── lib/
    └── jr-ssh-lib.sh     # Library functions sourced by the main script
/var/backups/jr-toolkit/ssh/ # Location for automatic backups
/var/log/jr-toolkit/ssh-wizard.log # Log file for all wizard actions
/etc/ssh/sshd_config.d/99-jr-toolkit.conf # SSHD hardening configuration
```

## ⚠️ Important Notes

*   Always backup your configuration before making major changes. The wizard provides a backup feature.
*   When hardening SSH (disabling password authentication), ensure you have verified key-based login from a separate terminal to avoid locking yourself out. The wizard will explicitly warn you.
*   The wizard defaults to managing keys for the user `jr`. You can modify `jr-ssh-wizard.sh` to change the `TARGET_USER` variable if needed.