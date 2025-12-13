#!/usr/bin/env bash
set -euo pipefail

NVME_ROOT="/mnt/nvme-root"

echo "[bridge] Mounting NVMe root..."
sudo mkdir -p "$NVME_ROOT"
sudo mount /dev/nvme0n1p2 "$NVME_ROOT"

echo "[bridge] Installing toolkit onto NVMe..."
sudo rsync -a --delete \
  --exclude='.git' \
  /home/jr/pi-toolkit/ \
  "$NVME_ROOT/home/jr/pi-toolkit/"

echo "[bridge] Installing jr-toolkit launcher..."
sudo tee "$NVME_ROOT/usr/local/bin/jr-toolkit" >/dev/null <<'SH'
#!/usr/bin/env bash
exec sudo /home/jr/pi-toolkit/pi-menu.sh
SH

sudo chmod 755 "$NVME_ROOT/usr/local/bin/jr-toolkit"

echo "[bridge] Fix ownership..."
sudo chown -R 1000:1000 "$NVME_ROOT/home/jr/pi-toolkit"

echo "[bridge] Unmount NVMe..."
sync
sudo umount "$NVME_ROOT"

echo "[bridge] Toolkit bridge installed on NVMe."
