# Pi-Factory: The Ultimate RPi 5 Lifecycle Toolkit

**Version 2.6**

Pi-Factory is a professional-grade CLI toolkit designed to manage the entire lifecycle of a Raspberry Pi 5. It transforms a standard SD card into a "Golden Key" capable of provisioning, tuning, and maintaining NVMe-based systems with ease and safety.

## 🚀 Features at a Glance

*   **Lifecycle Management:** Flash OS, Seed Configuration, Tune Hardware, Maintenance.
*   **Safety First:** "Danger Zone" wizards prevent accidental data wipes. Visual "Mode Indicators" tell you if you are on the Safe SD or the Live NVMe.
*   **Hardware Tuning:** Overclocking, Fan Control, PCIe Speed (Gen 2/3), and Boot Order management.
*   **Security:** Dedicated wizard for SSH keys, Firewall (UFW), and Fail2Ban.
*   **Diagnostics:** Comprehensive dashboards for System Health, Storage Benchmarks, and Network Speed.

---

## 🛠️ Installation (The Golden SD)

1.  **Flash Raspberry Pi OS (Lite or Desktop)** to a high-quality SD card.
2.  **Boot the Pi 5** from this SD card.
3.  **Install the Toolkit:**
    ```bash
    sudo apt update && sudo apt install -y git
    git clone https://github.com/dodgethis1/pi-factory.git /opt/pi-factory
    ```
4.  **Run it:**
    ```bash
    sudo /opt/pi-factory/main.sh
    ```
    *(Optional: Add an alias to your `.bashrc` for easy access)*

---

## 🛡️ The Safety Protocol

Pi-Factory is context-aware. The main menu header displays your current **Mode**:

*   **🟢 PROVISIONING MODE (Safe to Flash):**
    *   You are booted from SD Card or USB.
    *   It is SAFE to flash the NVMe drive.
    *   *Access:* Options 1, 2, 17, 21.
*   **🔴 LIVE SYSTEM MODE (Do Not Flash):**
    *   You are booted from the NVMe drive.
    *   Flash tools are LOCKED to prevent deleting your own OS.
    *   *Access:* Options 3-16, 18-22.

---

## 📖 Detailed Option Guide

### [ PROVISIONING ]
*These tools destroy or modify the target NVMe drive. Run from SD Card.*

*   **1) Flash NVMe Drive:**
    *   **Action:** Downloads the latest Raspberry Pi OS and flashes it to `/dev/nvme0n1`.
    *   **Safety:** Launches a "Danger Zone" wizard that requires you to verify the Drive Model/Serial and type "DESTROY" to proceed.
*   **2) Seed NVMe (Offline):**
    *   **Action:** Mounts the freshly flashed NVMe drive and injects configuration files (User, Wi-Fi, SSH) *before* the first boot.
    *   **Use Case:** Headless setup. Configure everything here, then reboot into a fully working system.

### [ CONFIGURATION ]
*Run these on the live system to set it up.*

*   **3) Configure Live System:**
    *   Sets Hostname, Timezone, and ensures basic connectivity.
*   **4) Security Wizard:**
    *   **Action:** This is an interactive submenu (wizard) for managing SSH keys, hardening SSH settings, and configuring firewall rules.
    *   **Usage:**
        *   **1) Import SSH Keys from GitHub:** Enter your GitHub username. The wizard fetches and previews your public keys. Confirm to append them to your `~/.ssh/authorized_keys`.
        *   **2) Import SSH Keys from USB:** Insert a USB drive. The wizard scans for `.pub` files, lists them, and asks for confirmation to import them to `~/.ssh/authorized_keys`.
        *   **3) Paste Public Key (Manual):** Allows you to paste a public key string (e.g., copied from your laptop) directly into the terminal. It is automatically validated and added to `authorized_keys`.
        *   **4) Generate New SSH Key Pair:** Creates an Ed25519 key pair for the current user. This key allows your Pi to authenticate with other services (e.g., GitHub, GitLab). The public key is displayed with instructions for use.
        *   **5) Harden SSH (Disable Passwords/Root):** Provides options to disable password authentication and/or root login via SSH. **CRITICAL WARNING:** Before disabling password authentication, ensure you have successfully logged in via SSH key from a *new* terminal. The wizard requires you to type "LOCKED" to confirm you understand the lockout risk.
        *   **6) Install Firewall (UFW):** Installs and configures Uncomplicated Firewall (UFW) to deny all incoming connections by default, while allowing SSH on port 22.
        *   **7) Install Fail2Ban:** Installs and configures Fail2Ban to protect against brute-force attacks on SSH.
*   **5-7) Install Software:**
    *   **Apps:** Pi-Apps, RPi Connect.
    *   **Cases:** Drivers for Pironman 5, Argon One V3.
    *   **Extras:** Docker, Tailscale, Cockpit.

### [ DIAGNOSTICS ]
*Check the health and performance of your Pi.*

*   **8) System Dashboard:**
    *   Real-time display of CPU Temp, Voltage, Throttling history, NVMe Link Speed, and IP address.
*   **9) Disk Benchmark:**
    *   Runs `fio` to test random 4K Read/Write performance (IOPS). The true test of system responsiveness.
*   **10) Network Benchmark:**
    *   Runs `speedtest-cli` (Internet) and `iperf3` (Local LAN) to verify connectivity.
*   **11) NVMe Speed Test:**
    *   Raw sequential read test to verify cable quality (aim for >800MB/s on Gen 3).

### [ HARDWARE TUNING ]
*Unlock the full potential of the Raspberry Pi 5.*

*   **12) Set PCIe Speed:**
    *   Toggle between **Gen 2** (Standard) and **Gen 3** (High Performance). *Note: Gen 3 requires a high-quality cable.*
*   **13) Pi Overclocking:**
    *   Apply safe overclock profiles (e.g., CPU @ 2.8GHz, GPU @ 900MHz). Includes auto-backup of `config.txt`.
*   **14) Pi Fan Control:**
    *   Configure the Active Cooler profile: **Silent**, **Standard**, or **Aggressive** (keeps NVMe cool).
*   **15) Boot Order Config:**
    *   Update EEPROM to prioritize **NVMe First** or **SD First**.
*   **17) Update Bootloader:**
    *   Checks for and flashes the latest stable EEPROM firmware.

### [ MAINTENANCE ]
*Keep your system clean and safe.*

*   **16) System Updates:** Runs `apt update && apt full-upgrade`.
*   **17) System Cleanup:** Clears apt cache, old logs, and temp files to free space.
*   **18) Backup Drive:**
    *   Creates a compressed `.img.gz` backup of a target drive.
    *   **Safety:** Prevents backing up the active root drive to avoid corruption.
*   **19) Clone Toolkit:** Copies this `pi-factory` folder to another USB stick.
*   **20) Update Toolkit:** Pulls the latest version of these scripts from GitHub.

---

## ❓ Troubleshooting

*   **"Update Toolkit" says up to date but I don't see new options?**
    *   Try running these commands manually:
        ```bash
        git fetch origin
        git reset --hard origin/main
        ```
*   **Flash NVMe fails?**
    *   Check your ribbon cable. Ensure `lspci` shows the drive.
    *   Verify the drive size is detected correctly in the Safety Wizard.
