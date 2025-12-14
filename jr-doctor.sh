#!/bin/bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/jr-lib.sh"

main() {
  jr_log_begin "doctor"

  echo "Toolkit root: $JR_TOOLKIT_ROOT" | tee -a "$JR_RUN_LOG"
  echo "Log dir:      ${JR_LOG_DIR}" | tee -a "$JR_RUN_LOG"
  echo

  echo "[1] Basic tools..." | tee -a "$JR_RUN_LOG"
  for b in bash awk sed grep lsblk findmnt mountpoint git; do
    command -v "$b" >/dev/null 2>&1 || { echo "MISSING: $b" | tee -a "$JR_RUN_LOG"; exit 2; }
  done
  echo "OK" | tee -a "$JR_RUN_LOG"
  echo

  echo "[2] Script syntax check (bash -n)..." | tee -a "$JR_RUN_LOG"
  local failed=0
  while IFS= read -r -d '' f; do
    bash -n "$f" || { echo "SYNTAX FAIL: $f" | tee -a "$JR_RUN_LOG"; failed=1; }
  done < <(find "$JR_TOOLKIT_ROOT" -maxdepth 1 -type f -name "*.sh" -print0)
  [[ "$failed" -eq 0 ]] || exit 3
  echo "OK" | tee -a "$JR_RUN_LOG"
  echo

  echo "[3] Launcher sanity..." | tee -a "$JR_RUN_LOG"
  if [[ -L /usr/local/bin/jr-toolkit ]]; then
    echo "/usr/local/bin/jr-toolkit -> $(readlink -f /usr/local/bin/jr-toolkit)" | tee -a "$JR_RUN_LOG"
  else
    echo "WARN: /usr/local/bin/jr-toolkit missing or not a symlink" | tee -a "$JR_RUN_LOG"
  fi
  echo

  echo "Doctor complete." | tee -a "$JR_RUN_LOG"
  jr_log_end 0
}

main "$@"
