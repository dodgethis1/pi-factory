#!/usr/bin/env bash
set -euo pipefail

FLASHER="/home/jr/pi-toolkit/flash-nvme.sh"
SEEDER="/home/jr/pi-toolkit/seed/postflash_nvme_seed.sh"
echo "[menu] Installing toolkit onto NVMe..."

bash /home/jr/pi-toolkit/install-toolkit-to-nvme.sh


if [[ ! -x "$FLASHER" ]]; then
  echo "ERROR: flasher not found or not executable: $FLASHER"
  exit 1
fi

echo "=== Running NVMe flasher ==="
bash "$FLASHER"

# If the flasher powers off, we never reach here. If it returns, we seed.
echo
echo "=== Running post-flash seeding ==="
if [[ -x "$SEEDER" ]]; then
  bash "$SEEDER"
else
  echo "ERROR: seeder not found or not executable: $SEEDER"
  exit 1
fi

echo "=== Flash + seed complete ==="
sync
