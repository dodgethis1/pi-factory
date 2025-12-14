#!/bin/bash
set -euo pipefail

echo "==============================================================="
echo " Argon case installer"
echo "==============================================================="
echo
echo "This installs Argon40 case support (fan/power button scripts)."
echo "It pulls the official installer script from download.argon40.com."
echo
echo "Type ARGON to proceed (exact)."
read -r confirm
[[ "$confirm" == "ARGON" ]] || { echo "Canceled."; exit 0; }

sudo apt-get update -y
sudo apt-get install -y curl

tmp="$(mktemp)"
curl -fsSL https://download.argon40.com/argon1.sh -o "$tmp"
sudo bash "$tmp"
rm -f "$tmp"

echo
echo "Done. Reboot recommended after install:"
echo "  sudo reboot now"
