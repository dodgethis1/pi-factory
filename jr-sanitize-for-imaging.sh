#!/bin/bash
set -euo pipefail

source /opt/jr-pi-toolkit/jr-confirm.sh

echo
echo "============================================================"
echo " JR PI TOOLKIT — SANITIZE RUNNING OS FOR IMAGING"
echo "============================================================"
echo
echo "This runs AGAINST THE LIVE SYSTEM you are booted into."
echo "It can cause SSH host key changes, machine-id changes,"
echo "and other identity resets that will annoy future-you."
echo
echo "If you really want to do this, type: SANITIZE LIVE"
echo

confirm_exact "SANITIZE LIVE" "Confirm" || die "Cancelled."

echo
echo "OK. Proceeding with sanitize steps..."
echo

# --- Put your existing sanitize actions below this line ---
# NOTE: Keep these minimal and deterministic. Example placeholders:
# sudo rm -f /etc/ssh/ssh_host_* || true
# sudo truncate -s 0 /etc/machine-id || true
# sudo rm -f /var/lib/dbus/machine-id || true
# sudo apt clean || true
# sudo journalctl --rotate || true
# sudo journalctl --vacuum-time=1s || true

echo
echo "Done."
