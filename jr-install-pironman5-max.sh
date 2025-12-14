#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="$SCRIPT_DIR/vendor"
REPO_DIR="$VENDOR/pironman5"

echo "==============================================================="
echo " Pironman 5 Max installer"
echo "==============================================================="
echo
echo "This installs SunFounder Pironman5 MAX software."
echo "It will clone/update into: $REPO_DIR"
echo
echo "Type PIR0NMAN to proceed (exact)."
read -r confirm
[[ "$confirm" == "PIR0NMAN" ]] || { echo "Canceled."; exit 0; }

sudo apt-get update -y
sudo apt-get install -y git python3

sudo mkdir -p "$VENDOR"
if [[ -d "$REPO_DIR/.git" ]]; then
  sudo git -C "$REPO_DIR" fetch --all --prune
  sudo git -C "$REPO_DIR" checkout max
  sudo git -C "$REPO_DIR" pull --ff-only
else
  sudo git clone -b max https://github.com/sunfounder/pironman5.git "$REPO_DIR"
fi

cd "$REPO_DIR"
sudo python3 install.py

echo
echo "Done. Reboot recommended after install:"
echo "  sudo reboot now"
