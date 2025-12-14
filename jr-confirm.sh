#!/bin/bash
set -euo pipefail

confirm_exact() {
  local expected="$1"
  local prompt="${2:-Type exactly: $expected}"
  local got=""
  read -rp "$prompt: " got
  [[ "$got" == "$expected" ]]
}

die() { echo "ERROR: $*" >&2; exit 1; }
