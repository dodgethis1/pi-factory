#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pause() { read -rp "Press Enter..." _; }

detect_boot_mode() {
  local root_src
  root_src="$(findmnt -n -o SOURCE / || true)"
  if [[ "$root_src" == /dev/mmcblk* ]]; then
    echo "SD"
  else
    echo "NVME"
  fi
}

log_dir="/var/log/jr-pi-toolkit"
last_log="${log_dir}/last-run.log"

while true; do
  clear || true
  echo "==============================================================="
  echo " JR PI TOOLKIT - DOCTOR / PREFLIGHT"
  echo "==============================================================="
  echo
  echo "Toolkit:  $SCRIPT_DIR"
  echo "Mode:     $(detect_boot_mode)"
  echo "Last log: $last_log"
  echo
  echo "Menu"
  echo "----"
  echo "0) Back"
  echo "1) Run FULL Doctor / Preflight"
  echo "2) View last run log"
  echo "3) Quick: bash syntax check (*.sh)"
  echo "4) Quick: launcher + root sanity"
  echo
  read -rp "Select: " c

  case "${c:-}" in
    0) exit 0 ;;
    1)
      [[ -x "$SCRIPT_DIR/jr-doctor.sh" ]] || { echo "ERROR: Missing jr-doctor.sh"; pause; continue; }
      sudo "$SCRIPT_DIR/jr-doctor.sh" || true
      pause
      ;;
    2)
      if [[ -f "$last_log" ]]; then
        command -v less >/dev/null 2>&1 && sudo less -R "$last_log" || sudo cat "$last_log"
      else
        echo "No last-run.log found yet in $log_dir"
      fi
      pause
      ;;
    3)
      echo "Running: bash -n on $SCRIPT_DIR/*.sh"
      failed=0
      shopt -s nullglob
      for f in "$SCRIPT_DIR"/*.sh; do
        bash -n "$f" || { echo "SYNTAX FAIL: $f"; failed=1; }
      done
      shopt -u nullglob
      [[ "$failed" -eq 0 ]] && echo "OK: no syntax errors"
      pause
      ;;
    4)
      echo "Detected root: $(findmnt -n -o SOURCE / || true)"
      echo
      echo "Launcher:"
      if [[ -e /usr/local/bin/jr-toolkit ]]; then
        ls -la /usr/local/bin/jr-toolkit
        echo
        echo "First 40 lines:"
        sed -n '1,40p' /usr/local/bin/jr-toolkit
      else
        echo "WARN: /usr/local/bin/jr-toolkit not found"
      fi
      pause
      ;;
    *)
      echo "Invalid selection."
      pause
      ;;
  esac
done
