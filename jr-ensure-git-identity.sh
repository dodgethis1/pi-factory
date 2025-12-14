#!/bin/bash
set -euo pipefail

NAME_WANT="dodgethis1"
EMAIL_WANT="dodgethis1@users.noreply.github.com"

name_cur="$(git config --global user.name || true)"
email_cur="$(git config --global user.email || true)"

echo "=== Git identity (global) ==="
echo "user.name : ${name_cur:-<unset>}"
echo "user.email: ${email_cur:-<unset>}"
echo

changed="no"

if [[ -z "${name_cur}" ]]; then
  git config --global user.name "$NAME_WANT"
  echo "Set user.name to: $NAME_WANT"
  changed="yes"
fi

if [[ -z "${email_cur}" ]]; then
  git config --global user.email "$EMAIL_WANT"
  echo "Set user.email to: $EMAIL_WANT"
  changed="yes"
fi

if [[ "$changed" == "no" ]]; then
  echo "OK: Git identity already configured. No changes made."
fi
