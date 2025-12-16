#!/usr/bin/env bash
set -uo pipefail

# 99-diagnostics/bench-disk.sh
# Comprehensive disk benchmarking for Raspberry Pi using FIO

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== DISK BENCHMARK (FIO) ===${NC}"
echo "This will perform random 4K read/write tests on the root filesystem."
echo "Ensure no critical operations are running during the test."
read -rp "Press Enter to continue or Ctrl+C to abort..."

# 1. Dependency Check
echo -e "\n${YELLOW}--- 1/2: Checking FIO ---${NC}"
if ! command -v fio &>/dev/null; then
    echo "FIO not found. Installing fio..."
    sudo apt-get update && sudo apt-get install -y fio
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: Failed to install FIO. Aborting.${NC}"
        exit 1
    fi
    echo "FIO installed."
else
    echo "FIO is already installed."
fi

# 2. Perform Benchmark
echo -e "\n${YELLOW}--- 2/2: Running FIO Benchmark ---${NC}"
echo "This may take a few minutes..."

# Target directory for the test files
TEST_DIR="/tmp/fio_test"
mkdir -p "$TEST_DIR"

# Run a combined random read/write test (4K block size, 1G file, 60s runtime)
# Using /tmp is generally safe for temporary test files.
sudo fio --name=rand-rw \
    --ioengine=libaio \
    --iodepth=64 \
    --rw=randrw \
    --rwmixread=70 \
    --bs=4k \
    --direct=1 \
    --size=1G \
    --numjobs=4 \
    --runtime=60 \
    --group_reporting \
    --filename="$TEST_DIR/fio_test_file" \
    --output-format=json \
    --output="$TEST_DIR/fio_results.json"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: FIO benchmark failed.${NC}"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo -e "\n${GREEN}--- BENCHMARK RESULTS ---${NC}"
# Parse and display key results from the JSON output
# Using 'jq' to parse JSON if available, otherwise just cat the file.
if command -v jq &>/dev/null; then
    echo "Summary:"
    jq -r '.jobs[0] | "Read: \( .read.iops | round ) IOPS, \( .read.bw_bytes / 1024 / 1024 | round ) MB/s\nWrite: \( .write.iops | round ) IOPS, \( .write.bw_bytes / 1024 / 1024 | round ) MB/s"' "$TEST_DIR/fio_results.json"
else
    echo "FIO results (raw JSON - install 'jq' for a nicer summary):"
    cat "$TEST_DIR/fio_results.json"
fi

# Clean up
echo -e "\nCleaning up test files..."
rm -rf "$TEST_DIR"

echo -e "\n${BLUE}=== DISK BENCHMARK COMPLETE ===${NC}"
