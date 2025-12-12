#!/usr/bin/env bash
set -euo pipefail

USER_EXPECTED="jr"
HOME_EXPECTED="/home/jr"
REPO_DIR="/home/jr/pi-provision"
DONE_MARKER="/var/local/pi-provision.done"
LOG_TAG="[pi-provision]"

say() { echo "$LOG_TAG $*"; }

if [[ "$(id -un)" != "$USER_EXPECTED" ]]; then
  echo "$LOG_TAG ERROR: must run as user '$USER_EXPECTED' (current: $(id -un))" >&2
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "$LOG_TAG ERROR: repo dir missing: $REPO_DIR" >&2
  exit 1
fi

if [[ -f "$DONE_MARKER" ]]; then
  say "Done marker exists ($DONE_MARKER). Exiting."
  exit 0
fi

say "Starting provisioning on $(hostname) ..."

# 1) Ensure Pi-Apps present (assumes you install it once; but we can bootstrap later if you want)
if [[ ! -d "/pi-apps" ]]; then
  say "Pi-Apps not found. Bootstrapping Pi-Apps..."
  sudo apt-get update
  sudo apt-get install -y git
  git clone --depth=1 https://github.com/Botspot/pi-apps "/pi-apps"
fi

# 2) Update Pi-Apps (best effort)
if [[ -x "$HOME_EXPECTED/pi-apps/update" ]]; then
  say "Updating Pi-Apps..."
  "$HOME_EXPECTED/pi-apps/update" || true
fi

# 3) Install apps listed in pi-apps/install.list
INSTALL_LIST="$REPO_DIR/pi-apps/install.list"
if [[ -f "$INSTALL_LIST" ]]; then
  while IFS= read -r app || [[ -n "$app" ]]; do
    [[ -z "$app" ]] && continue
    [[ "$app" =~ ^# ]] && continue

    say "Installing Pi-App: $app"
    if [[ -x "$HOME_EXPECTED/pi-apps/manage" ]]; then
      "$HOME_EXPECTED/pi-apps/manage" install "$app"
    elif [[ -x "$HOME_EXPECTED/pi-apps/install" ]]; then
      "$HOME_EXPECTED/pi-apps/install" "$app"
    else
      say "ERROR: Pi-Apps CLI not found (manage/install)."
      exit 1
    fi
  done < "$INSTALL_LIST"
fi

# 4) Desktop icons (for jr)
DESKTOP_DIR="$HOME_EXPECTED/Desktop"
mkdir -p "$DESKTOP_DIR"

if [[ -f "$REPO_DIR/desktop/all-is-well.desktop" ]]; then
  install -m 0755 "$REPO_DIR/desktop/all-is-well.desktop" "$DESKTOP_DIR/all-is-well.desktop"
  # Some desktops require marking as trusted; this helps on some setups
  chmod +x "$DESKTOP_DIR/all-is-well.desktop" || true
fi

# 5) Enable Raspberry Pi Connect (best-effort; sign-in may still be manual)
# Service names can vary by release; we'll try a few.
say "Enabling Raspberry Pi Connect services (best effort)..."
sudo systemctl enable --now rpi-connect 2>/dev/null || true
sudo systemctl enable --now rpi-connectd 2>/dev/null || true
sudo systemctl enable --now rpi-connect-wayvnc 2>/dev/null || true

# 6) Mark done + disable service so it won't rerun every boot
say "Writing done marker..."
sudo mkdir -p /var/local
sudo touch "$DONE_MARKER"
sudo chown root:root "$DONE_MARKER"
sudo chmod 0644 "$DONE_MARKER"

say "Disabling pi-provision service (one-shot complete)..."
sudo systemctl disable pi-provision 2>/dev/null || true

say "Provisioning complete."
