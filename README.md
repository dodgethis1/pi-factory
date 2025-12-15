# Pi-Factory: The Golden Key

**A clean, automated toolkit to turn any Raspberry Pi 5 into your perfect setup.**

## 🚀 Quick Start

### Prerequisites
1.  **Flash an SD Card:** Install Raspberry Pi OS (Lite is fine) on a spare SD card.
2.  **Boot:** Insert it into your Pi 5 and boot up.
3.  **Download this Toolkit:**
    ```bash
    sudo apt update && sudo apt install -y git
    git clone https://github.com/YOUR_USERNAME/pi-factory.git
    cd pi-factory
    ```

### Usage
1.  **Edit Config:** Open `config/settings.conf` and set your Wi-Fi, User, and Hostname.
    ```bash
    nano config/settings.conf
    ```
2.  **Run:** Execute the main script:
    ```bash
    sudo bash main.sh
    ```
3.  **Follow the Menu:**
    *   **Step 1:** Flash the NVMe drive (Destructive!).
    *   **Step 2:** Configure the system (User, Network, Keys).
    *   **Step 3:** Install Software (Pi-Apps, RPi Connect).

## 📂 Project Structure

*   `00-prep/` - Tools to prepare your "Golden Key" USB/SD card.
*   `10-flash/` - Scripts that wipe and flash the NVMe drive.
*   `20-configure/` - Setup scripts for User, Network, and System settings.
*   `30-software/` - Installers for Apps and Tools.
*   `config/` - **Your settings live here.**
*   `docs/` - Detailed explanations of how everything works.

## ⚠️ Safety First
*   This tool is **destructive**. Step 1 will ERASE the target NVMe drive.
*   Always back up your data before running the Flasher.
