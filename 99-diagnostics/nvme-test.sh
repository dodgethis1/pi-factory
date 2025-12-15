#!/usr/bin/env bash
set -uo pipefail

# 99-diagnostics/nvme-test.sh
# Comprehensive NVMe health and speed test for Raspberry Pi 5

echo "=== NVMe DIAGNOSTICS TOOL ==="

NVME_DEV="/dev/nvme0n1"

# 1. Dependency Check
echo "[1/5] Checking tools..."
if ! command -v smartctl &>/dev/null; then
    echo "Installing smartmontools..."
    apt-get update && apt-get install -y smartmontools pciutils
fi

# 2. Presence Check
echo "[2/5] Checking Device Presence..."
if [[ ! -b "$NVME_DEV" ]]; then
    echo "FAIL: $NVME_DEV not found!"
    echo "The drive is not detected by the kernel."
    echo "Possibilities: Loose cable, bad adapter, power issue."
    exit 1
fi
echo "PASS: Device found."
lsblk -o NAME,SIZE,MODEL,SERIAL "$NVME_DEV"

# 3. PCIe Link Status
echo
echo "[3/5] Checking PCIe Link Speed..."
# Find the NVMe controller on the PCI bus
PCI_ADDR=$(lspci | grep -i nvme | cut -d' ' -f1)
if [[ -n "$PCI_ADDR" ]]; then
    LNKCAP=$(lspci -vv -s "$PCI_ADDR" | grep "LnkCap:" | sed 's/^[ 	]*//')
    LNKSTA=$(lspci -vv -s "$PCI_ADDR" | grep "LnkSta:" | sed 's/^[ 	]*//')
    
    echo "Capabilities: $LNKCAP"
    echo "Current Link: $LNKSTA"
    
    if echo "$LNKSTA" | grep -q "Speed 2.5GT/s"; then
        echo "WARNING: Link is running at Gen 1 (Slowest). Cable signal integrity is poor."
    elif echo "$LNKSTA" | grep -q "Speed 5GT/s"; then
        echo "INFO: Link is running at Gen 2 (Standard)."
    elif echo "$LNKSTA" | grep -q "Speed 8GT/s"; then
        echo "INFO: Link is running at Gen 3 (Fast)."
    fi
    
    if echo "$LNKSTA" | grep -q "Width x1"; then
        echo "PASS: Link width is x1 (Correct for Pi 5)."
    else
        echo "WARNING: Unexpected link width."
    fi
else
    echo "FAIL: Could not find NVMe controller on PCI bus."
fi

# 4. SMART Health
echo
echo "[4/5] Checking SMART Health..."
smartctl -H "$NVME_DEV" | grep "test result"
# Print critical warnings
smartctl -A "$NVME_DEV" | grep -E "Critical Warning|Temperature|Available Spare|Media and Data Integrity Errors"

# 5. Read Speed Test
echo
echo "[5/5] performing READ Speed Test (1GB)..."
# We read 1GB from the drive to /dev/null
# This stresses the link without destroying data.
# We use dd with direct I/O to bypass cache.
dd if="$NVME_DEV" of=/dev/null bs=1M count=1024 status=progress iflag=direct

EXIT_CODE=$?
echo
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "=== DIAGNOSTICS COMPLETE ==="
    echo "Review the Read Speed above."
    echo " - < 100 MB/s:  CRITICAL FAILURE (Bad Cable/Adapter)"
    echo " - 100-300 MB/s: OK (Gen 1/Gen 2)"
    echo " - > 400 MB/s:   EXCELLENT (Gen 2/Gen 3)"
else
    echo "FAIL: Read test crashed. Drive dropped offline."
fi
