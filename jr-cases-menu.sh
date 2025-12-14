#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pause(){ read -rp "Press Enter to return..." _; }

while true; do
  clear || true
  echo "==============================================================="
  echo " JR PI TOOLKIT - CASE INSTALLERS (OPT-IN)"
  echo "==============================================================="
  echo
  echo "Optional case helper installers. Safe to run repeatedly."
  echo
  echo "0) Back"
  echo "1) Pironman 5 Max helper installer"
  echo "2) Argon case helper installer"
  echo
  read -rp "Select: " c

  case "${c:-}" in
    0) exit 0 ;;
    1)
      sudo "$SCRIPT_DIR/jr-install-pironman5-max.sh"
      pause
      ;;
    2)
      sudo "$SCRIPT_DIR/jr-install-argon-case.sh"
      pause
      ;;
    *)
      echo "Invalid selection."
      sleep 1
      ;;
  esac
done
