#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYDIR="${SCRIPT_DIR}/keys/public"
TARGET_USER="jr"
SSH_DIR="/home/${TARGET_USER}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

pause() { echo; read -rp "Press Enter to continue... " _; }

pi_host() { hostname 2>/dev/null || echo "raspberrypi"; }
pi_ip() { hostname -I 2>/dev/null | awk '{print $1}' | tr -d '\r' || true; }

banner() {
  clear || true
  echo "==============================================================="
  echo "  JR PI TOOLKIT - SSH KEY WIZARD (PUBLIC KEYS ONLY)"
  echo "==============================================================="
  echo
  echo "Toolkit key folder: ${KEYDIR}/"
  echo "Will seed to       : ${AUTH_KEYS}"
  echo
  echo "STOP: This screen runs on the PI."
  echo "      When it shows a Windows command, run it on WINDOWS PowerShell."
  echo
}

ask_label() {
  local label
  echo "Label = short name for the PC. Use: laptop or desktop." >&2
  read -rp "Label: " label
  label="${label// /}"
  if [[ -z "${label}" || ! "${label}" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "ERROR: label must be letters/numbers/_/- only." >&2
    return 1
  fi
  printf "%s" "${label}"
}

box() {
  local title="$1"
  shift
  echo
  echo "#################### ${title} ####################"
  printf "%s\n" "$@"
  echo "###############################################################"
}

list_keys() {
  echo
  echo "Keys currently in toolkit:"
  if ls -1 "${KEYDIR}"/*.pub >/dev/null 2>&1; then
    ls -la "${KEYDIR}"/*.pub
  else
    echo "  (none yet)"
  fi
}

save_pubkey_line() {
  local label="$1"
  local outfile="${KEYDIR}/${label}.pub"
  local keyline

  echo
  echo "PASTE INTO THIS PI NOW:"
  echo "Paste the SINGLE public key line (starts with ssh-ed25519 or ssh-rsa), then press Enter."
  read -r keyline

  if [[ ! "${keyline}" =~ ^ssh-(ed25519|rsa)[[:space:]] ]]; then
    echo "ERROR: That does not look like a public key line."
    echo "On Windows run:  type <file>.pub"
    echo "Copy the full ssh-ed25519... line and paste it here."
    return 1
  fi

  printf "%s\n" "${keyline}" > "${outfile}"
  chmod 0644 "${outfile}"
  echo
  echo "SAVED OK: ${outfile}"
}

seed_authorized_keys() {
  shopt -s nullglob
  local pubs=( "${KEYDIR}"/*.pub )
  shopt -u nullglob

  if [ "${#pubs[@]}" -eq 0 ]; then
    echo "ERROR: No .pub files in ${KEYDIR}"
    return 1
  fi

  id "${TARGET_USER}" >/dev/null 2>&1 || { echo "ERROR: user '${TARGET_USER}' not found."; return 1; }

  mkdir -p "${SSH_DIR}"
  chmod 700 "${SSH_DIR}"
  chown "${TARGET_USER}:${TARGET_USER}" "${SSH_DIR}"

  touch "${AUTH_KEYS}"
  chmod 600 "${AUTH_KEYS}"
  chown "${TARGET_USER}:${TARGET_USER}" "${AUTH_KEYS}"

  local added=0
  for f in "${pubs[@]}"; do
    while IFS= read -r line; do
      [[ -z "${line}" ]] && continue
      [[ "${line}" =~ ^# ]] && continue
      if ! sudo -u "${TARGET_USER}" grep -qxF "${line}" "${AUTH_KEYS}"; then
        echo "Adding: $(basename "${f}")"
        echo "${line}" | sudo -u "${TARGET_USER}" tee -a "${AUTH_KEYS}" >/dev/null
        added=$((added+1))
      fi
    done < "${f}"
  done

  echo
  echo "Seed complete. New keys added: ${added}"
}

guided_add_pc() {
  local label host ip keybase

  banner
  label="$(ask_label)" || return 1

  host="$(pi_host)"
  ip="$(pi_ip)"
  keybase="\$env:USERPROFILE\\.ssh\\jr_pi_${label}_ed25519"

  banner
  echo "GUIDED SETUP for PC label: ${label}"
  echo

  box "STEP 1 (RUN THIS ON WINDOWS POWERSHELL)" \
"ssh-keygen -t ed25519 -a 64 -f ${keybase} -C jr-${label}"

  echo
  echo "Run that on WINDOWS PowerShell (not on the Pi)."
  pause

  box "STEP 2 (RUN THIS ON WINDOWS POWERSHELL)" \
"type ${keybase}.pub" \
"" \
"# Copy the single ssh-ed25519... line it prints."

  echo
  echo "Run that on WINDOWS, copy the ssh-ed25519 line."
  pause

  banner
  echo "NOW BACK ON THE PI: paste the ssh-ed25519 line here."
  save_pubkey_line "${label}" || return 1

  echo
  echo "Now seeding /home/jr/.ssh/authorized_keys..."
  seed_authorized_keys
  echo

  banner
  echo "DONE. Test from WINDOWS PowerShell:"
  if [[ -n "${ip}" ]]; then
    box "STEP 3 (RUN THIS ON WINDOWS POWERSHELL)" \
"ssh ${TARGET_USER}@${ip}" \
"" \
"# If you get a host-key warning after imaging:" \
"ssh-keygen -R ${ip}"
  else
    box "STEP 3 (RUN THIS ON WINDOWS POWERSHELL)" \
"ssh ${TARGET_USER}@${host}" \
"" \
"# If you get a host-key warning after imaging:" \
"ssh-keygen -R <pi-ip>"
  fi
}

while true; do
  banner
  echo "0) Back"
  echo "1) Guided: Add a PC key (Windows commands + paste-back step)"
  echo "2) List toolkit keys"
  echo "3) Seed keys into /home/jr/.ssh/authorized_keys (deduped)"
  echo
  read -rp "Choose: " c
  case "${c:-}" in
    0) exit 0 ;;
    1) guided_add_pc; pause ;;
    2) list_keys; pause ;;
    3) seed_authorized_keys; pause ;;
    *) echo "Pick 0-3."; pause ;;
  esac
done
