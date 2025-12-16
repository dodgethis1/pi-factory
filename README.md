# Pi-Factory: The Golden Key

**A clean, automated toolkit to turn any Raspberry Pi 5 into your perfect setup.**

Turn a "Golden SD Card" into a factory that churns out fully configured NVMe Pis.

## 🚀 Quick Start

### 1. Prepare the Golden SD
1.  Flash Raspberry Pi OS (Lite or Desktop) to an SD card.
2.  Boot the Pi from SD.
3.  **Install the Toolkit:**
    ```bash
    sudo apt update && sudo apt install -y git
    git clone https://github.com/YOUR_USERNAME/pi-factory.git
    cd pi-factory
    ```
4.  **Install the Shortcut:**
    ```bash
    sudo bash install-shortcut.sh
    ```
    *Now you can run the tool by typing `pi-factory` from anywhere!*

### 2. Configure Settings
Edit `config/settings.conf` to set your target User, Password, and Wi-Fi credentials.
```bash
nano config/settings.conf
```

### 3. Run the Factory
Type `pi-factory` to open the menu.

---

## 📋 Menu Options

### [ Provisioning ]
*   **1) Flash NVMe Drive:** (Destructive) Downloads the latest Raspberry Pi OS and flashes it to the NVMe drive.
*   **2) Seed NVMe (Offline):** Pre-configures the NVMe drive *before* you boot it (enables SSH, creates user, sets Wi-Fi). Use this if you are headless.

### [ Configuration ]
*   **3) Configure Live System:** Run this *after* booting into the NVMe drive. It sets up your hostname, user, and imports **SSH Keys from GitHub**.
*   **9) Clone Toolkit:** Back up the toolkit to a USB stick or another SD card.

### [ Software ]
*   **4) Install Apps:** Installs **Pi-Apps** and **Raspberry Pi Connect**.
*   **5) Install Cases:** Drivers for **Pironman 5** and **Argon One V3/V5**.
*   **6) Install Extras:** One-click installers for **Docker**, **Tailscale**, **Cockpit**, etc.

### [ Maintenance ]
*   **99) Run NVMe Diagnostics:** Checks PCIe link speed (Gen 2/3) and drive health. **Use this if your drive is slow!**
*   **10) Apply NVMe Kernel Fixes:** Applies kernel flags to fix instability issues.
*   **11) Force PCIe Gen 1:** Emergency mode for bad cables.

## ⚠️ Safety First
*   **Option 1** is DESTRUCTIVE. It will erase the NVMe drive.
*   Always check your power supply (Official 27W recommended) for NVMe stability.

