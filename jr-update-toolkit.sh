#!/bin/bash
set -euo pipefail
cd /opt/jr-pi-toolkit

echo "=== BEFORE ==="
git status -sb
git rev-parse --short HEAD || true
echo

# refuse if dirty
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: toolkit repo has local changes. Commit/stash first."
  exit 1
fi

git pull --ff-only

echo
echo "=== AFTER ==="
git status -sb
git rev-parse --short HEAD || true
