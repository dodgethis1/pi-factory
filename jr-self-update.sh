#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

pause() { echo; echo "Press Enter to continue..."; read -r _; }

echo "==============================================================="
echo "  JR PI TOOLKIT - SELF UPDATE (fast-forward only)"
echo "==============================================================="
echo

command -v git >/dev/null 2>&1 || { echo "ERROR: git not installed."; echo "Fix: sudo apt update && sudo apt install -y git"; exit 1; }
[ -d .git ] || { echo "ERROR: ${SCRIPT_DIR} is not a git repo (.git missing)."; exit 1; }

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

echo "Repo    : ${SCRIPT_DIR}"
echo "Branch  : ${BRANCH}"
echo "Upstream: ${UPSTREAM:-<none>}"
echo

if [ -n "$(git status --porcelain)" ]; then
  echo "Local changes detected (DIRTY working tree)."
  echo
  echo "1) Stash changes (including untracked) and continue"
  echo "2) Abort update"
  echo
  read -r -p "Choose: " d
  case "$d" in
    1)
      STASH_MSG="jr-toolkit auto-stash $(date +%Y-%m-%d_%H%M%S)"
      git stash push -u -m "${STASH_MSG}"
      echo "OK: stashed: ${STASH_MSG}"
      echo
      ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac
fi

echo "Fetching origin..."
git fetch --prune origin
echo

if [ -z "${UPSTREAM}" ]; then
  if git show-ref --quiet refs/remotes/origin/main; then
    git branch --set-upstream-to=origin/main "${BRANCH}" >/dev/null 2>&1 || true
    UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
    echo "Set upstream to: ${UPSTREAM:-<still none>}"
    echo
  fi
fi

[ -n "${UPSTREAM}" ] || { echo "ERROR: No upstream configured."; echo "Fix: git branch --set-upstream-to=origin/main ${BRANCH}"; exit 1; }

LOCAL="$(git rev-parse HEAD)"
REMOTE="$(git rev-parse "${UPSTREAM}")"
BASE="$(git merge-base HEAD "${UPSTREAM}")"

echo "Local : ${LOCAL:0:7}"
echo "Remote: ${REMOTE:0:7}"
echo "Base : ${BASE:0:7}"
echo

if [ "${LOCAL}" = "${REMOTE}" ]; then
  echo "Already up to date."
  pause
  exit 0
fi

if [ "${LOCAL}" = "${BASE}" ]; then
  echo "Fast-forward available. Pulling (ff-only)..."
  git pull --ff-only
  NEW="$(git rev-parse HEAD)"
  echo
  echo "Updated: ${LOCAL:0:7} -> ${NEW:0:7}"
  echo
  echo "Restart the toolkit to use the new code."
  pause
  exit 0
fi

if [ "${REMOTE}" = "${BASE}" ]; then
  echo "Local branch is ahead of remote. No pull performed."
  echo "If intentional, push your commits."
  pause
  exit 0
fi

echo "ERROR: Local and remote have diverged (not fast-forward)."
echo "Refusing to auto-merge."
echo "Manual fix: git pull --rebase  (or other deliberate choice)"
pause
exit 1
