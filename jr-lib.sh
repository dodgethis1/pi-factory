#!/bin/bash
set -euo pipefail

# Resolve toolkit root (symlink-safe when sourced)
JR_TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config if present
JR_CONF="$JR_TOOLKIT_ROOT/jr-toolkit.conf"
if [[ -f "$JR_CONF" ]]; then
  # shellcheck disable=SC1090
  source "$JR_CONF"
fi

: "${JR_LOG_DIR:=/var/log/jr-pi-toolkit}"

jr_require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: must run as root (use sudo)." >&2
    exit 1
  fi
}

jr_mkdir_logs() {
  mkdir -p "$JR_LOG_DIR"
  chmod 0755 "$JR_LOG_DIR" || true
}

jr_log_begin() {
  jr_mkdir_logs
  local name="$1"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  JR_RUN_LOG="$JR_LOG_DIR/run-${ts}-${name}.log"
  ln -sf "$JR_RUN_LOG" "$JR_LOG_DIR/last-run.log"
  echo "=== BEGIN $name @ $(date -Is) ===" | tee -a "$JR_RUN_LOG"
}

jr_log_end() {
  local rc="${1:-0}"
  echo "=== END rc=$rc @ $(date -Is) ===" | tee -a "$JR_RUN_LOG"
  return "$rc"
}

jr_confirm_danger() {
  local prompt="${1:-Type the confirmation phrase to continue}"
  echo
  echo "$prompt"
  echo "Required: ${JR_DANGER_PHRASE:-FLASH}"
  read -r -p "> " reply
  if [[ "$reply" != "${JR_DANGER_PHRASE:-FLASH}" ]]; then
    echo "ABORTED: confirmation phrase mismatch."
    exit 1
  fi
}
