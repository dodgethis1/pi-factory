#!/usr/bin/env bash
set -uo pipefail

# 99-diagnostics/bench-net.sh
# Network benchmarking for Raspberry Pi using speedtest-cli and iperf3

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== NETWORK BENCHMARK ===${NC}"
echo "This tool will perform internet speed tests (Ookla) and local network (iperf3) tests."
echo "Ensure good network connectivity."
read -rp "Press Enter to continue or Ctrl+C to abort..."

# --- 1. Dependency Check (speedtest-cli) ---
echo -e "\n${YELLOW}--- 1/3: Checking speedtest-cli ---${NC}"
if ! command -v speedtest &>/dev/null; then
    echo "speedtest-cli not found. Installing..."
    # speedtest-cli is usually installed via curl | bash
    # First, install curl if not present
    if ! command -v curl &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y curl
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: Failed to install curl. Cannot install speedtest-cli. Aborting.${NC}"
            exit 1
        fi
    fi
    curl -sL https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
    sudo apt-get install -y speedtest
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to install speedtest-cli. Aborting.${NC}"
        exit 1
    fi
    echo "speedtest-cli installed."
else
    echo "speedtest-cli is already installed."
fi

# --- 2. Internet Speed Test (Ookla) ---
echo -e "\n${YELLOW}--- 2/3: Running Internet Speed Test (Ookla) ---${NC}"
echo "This will connect to the nearest Ookla server. Please be patient."
speedtest

# --- 3. Dependency Check (iperf3) ---
echo -e "\n${YELLOW}--- 3/3: Checking iperf3 ---${NC}"
if ! command -v iperf3 &>/dev/null; then
    echo "iperf3 not found. Installing iperf3..."
    sudo apt-get update && sudo apt-get install -y iperf3
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to install iperf3. Local network test skipped.${NC}"
    else
        echo "iperf3 installed."
        # --- 4. Local Network Test (iperf3) ---
        echo -e "\n${YELLOW}--- 4/3: Running Local Network Test (iperf3) ---${NC}"
        echo "To perform a full iperf3 test, you need an iperf3 server running on another machine."
        echo "e.g., on a desktop: 'iperf3 -s'"
        read -rp "Enter the IP address of an iperf3 server on your local network (or leave blank to skip): " IPERF_SERVER
        if [[ -n "$IPERF_SERVER" ]]; then
            echo "Running iperf3 client test against $IPERF_SERVER..."
            iperf3 -c "$IPERF_SERVER" -P 5 -t 10
        else
            echo "Local network test skipped."
        fi
    fi
else
    echo "iperf3 is already installed."
    # --- 4. Local Network Test (iperf3) ---
    echo -e "\n${YELLOW}--- 4/3: Running Local Network Test (iperf3) ---${NC}"
    echo "To perform a full iperf3 test, you need an iperf3 server running on another machine."
    echo "e.g., on a desktop: 'iperf3 -s'"
    read -rp "Enter the IP address of an iperf3 server on your local network (or leave blank to skip): " IPERF_SERVER
    if [[ -n "$IPERF_SERVER" ]]; then
        echo "Running iperf3 client test against $IPERF_SERVER..."
        iperf3 -c "$IPERF_SERVER" -P 5 -t 10
    else
        echo "Local network test skipped."
    fi
fi

echo -e "\n${BLUE}=== NETWORK BENCHMARK COMPLETE ===${NC}"
