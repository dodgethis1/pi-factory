#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="${SCRIPT_DIR}"

# Simple colored output (safe if terminal doesn't support)
RED="$(tput setaf 1 2>/dev/null || true)"
GRN="$(tput setaf 2 2>/dev/null || true)"
YLW="$(tput setaf 3 2>/dev/null || true)"
RST="$(tput sgr0 2>/dev/null || true)"

ok()   { echo "${GRN}OK${RST}   $*"; }
warn() { echo "${YLW}WARN${RST} $*"; }
bad()  { echo "${RED}FAIL${RST} $*"; FAIL=1; }

FAIL=0

echo "==============================================================="
echo " JR PI TOOLKIT - DOCTOR / PREFLIGHT"
echo "==============================================================="
echo

# Host + mode sanity
ROOT_SRC="$(findmnt -no SOURCE / || true)"
HOST="$(hostname || true)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"

if [[ "$ROOT_SRC" == /dev/mmcblk* ]]; then
  MODE="SD (golden)"
elif [[ "$ROOT_SRC" == /dev/nvme* ]]; then
  MODE="NVMe (runtime)"
else
  MODE="Unknown"
fi

echo "Host:         ${HOST}"
echo "IP:           ${IP:-unknown}"
echo "Root:         ${ROOT_SRC:-unknown}"
echo "Mode:         ${MODE}"
echo "Toolkit root: ${TOOLKIT_ROOT}"
echo

# Launcher sanity
LAUNCHER="/usr/local/bin/jr-toolkit"
MENU="${TOOLKIT_ROOT}/pi-menu.sh"

if [[ -f "$LAUNCHER" ]]; then
  if grep -q "/opt/jr-pi-toolkit/pi-menu.sh" "$LAUNCHER"; then
    ok "Launcher points at /opt/jr-pi-toolkit/pi-menu.sh"
  else
    warn "Launcher exists but does not clearly reference /opt/jr-pi-toolkit/pi-menu.sh: $LAUNCHER"
  fi
else
  warn "Launcher missing: $LAUNCHER"
fi

# Required files
REQ=(
  "pi-menu.sh"
  "jr-self-update.sh"
  "jr-update-toolkit.sh"
  "jr-provision.sh"
  "jr-firstrun.sh"
  "jr-set-nvme-network.sh"
  "jr-golden-sd-build-nvme.sh"
  "jr-seed-ssh-keys.sh"
  "jr-cases-menu.sh"
  "jr-install-pironman5-max.sh"
  "jr-install-argon-case.sh"
)

echo
echo "Checking required files..."
for f in "${REQ[@]}"; do
  p="${TOOLKIT_ROOT}/${f}"
  if [[ -e "$p" ]]; then
    ok "Present: $f"
  else
    bad "Missing: $f"
  fi
done

echo
echo "Checking executable bits..."
for f in "${REQ[@]}"; do
  p="${TOOLKIT_ROOT}/${f}"
  [[ -e "$p" ]] || continue
  if [[ -x "$p" ]]; then
    ok "Executable: $f"
  else
    bad "Not executable: $f (fix: chmod +x ${p})"
  fi
done

echo
echo "Checking bash syntax (bash -n) for *.sh..."
while IFS= read -r -d '' f; do
  if bash -n "$f" 2>/tmp/jr-doctor.syntax.err; then
    ok "Syntax: $(basename "$f")"
  else
    bad "Syntax error: $(basename "$f")"
    sed -n '1,8p' /tmp/jr-doctor.syntax.err | sed 's/^/  /'
  fi
done < <(find "$TOOLKIT_ROOT" -maxdepth 1 -type f -name "*.sh" -print0)

echo
echo "Checking git ignore for runtime keys..."
if [[ -f "${TOOLKIT_ROOT}/.gitignore" ]] && grep -qE '^keys/public/' "${TOOLKIT_ROOT}/.gitignore"; then
  ok ".gitignore contains keys/public/"
else
  warn ".gitignore does not include keys/public/ (you probably want it ignored)"
fi

echo
echo "Checking Pi-Apps presence..."
if [[ -x /home/jr/pi-apps/pi-apps || -x /home/jr/pi-apps/updater ]]; then
  ok "Pi-Apps installed in /home/jr/pi-apps"
else
  warn "Pi-Apps not found in /home/jr/pi-apps"
fi

echo
echo "==============================================================="
if [[ "$FAIL" -eq 0 ]]; then
  echo "${GRN}DOCTOR RESULT: CLEAN${RST}"
else
  echo "${RED}DOCTOR RESULT: ISSUES FOUND${RST}"
fi
echo "==============================================================="
exit "$FAIL"
