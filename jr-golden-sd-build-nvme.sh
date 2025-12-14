#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
KEYDIR="${SCRIPT_DIR}/keys/public"

pause() { echo; read -rp "Press Enter to continue... " _; }

die() { echo "ERROR: $*" >&2; exit 1; }

banner() {
  clear || true
  echo "==============================================================="
  echo "  JR PI TOOLKIT - GUIDED GOLDEN SD -> NVMe BUILD (JASONPROOF)"
  echo "==============================================================="
  echo
}

confirm_one_word() {
  local phrase="$1"
  echo
  echo "CONFIRM REQUIRED"
  echo "Type exactly: ${phrase}"
  read -rp "> " typed
  [[ "${typed:-}" == "${phrase}" ]]
}

require_sd_boot() {
  [[ "$ROOT_SRC" == /dev/mmcblk* ]] || die "This guided build must be run while booted from the Golden SD (root is $ROOT_SRC)."
}

pick_nvme_disk() {
  local d
  d="$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^nvme/ {print "/dev/"$1; exit}')"
  [[ -n "${d:-}" ]] || die "No NVMe disk detected (expected something like /dev/nvme0n1)."
  echo "$d"
}

require_keys_present() {
  shopt -s nullglob
  local pubs=( "${KEYDIR}"/*.pub )
  shopt -u nullglob
  [[ "${#pubs[@]}" -gt 0 ]] || die "No public keys found in ${KEYDIR}. Run Option 13 first to add your laptop/desktop key(s)."
}

net_info() {
  local ip gw
  ip="$(hostname -I 2>/dev/null | awk '{print $1}' | tr -d '\r' || true)"
  gw="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}' || true)"
  echo "IP      : ${ip:-none}"
  echo "Gateway : ${gw:-none}"
}

run_if_exists() {
  local f="$1"
  [[ -x "${SCRIPT_DIR}/${f}" ]] || die "Missing ${f} in toolkit."
  sudo "${SCRIPT_DIR}/${f}"
}

mount_nvme_root() {
  local nvme="$1"
  local part mp
  part="$(lsblk -lnpo NAME,FSTYPE,TYPE "${nvme}" | awk '$2=="ext4" && $3=="part" {print $1; exit}')"
  [[ -n "${part:-}" ]] || die "Could not find an ext4 root partition on ${nvme} after flashing."

  mp="/mnt/jr-nvme-root"
  sudo mkdir -p "${mp}"

  # If already mounted, unmount first (best effort)
  if mountpoint -q "${mp}"; then
    sudo umount "${mp}" || true
  fi

  sudo mount "${part}" "${mp}"
  echo "${mp}"
}

seed_keys_into_nvme() {
  local mp="$1"
  local sshdir="${mp}/home/jr/.ssh"
  local auth="${sshdir}/authorized_keys"

  sudo mkdir -p "${sshdir}"
  sudo chmod 700 "${sshdir}"
  sudo touch "${auth}"
  sudo chmod 600 "${auth}"

  # Combine, dedupe, and write keys
  sudo bash -lc "cat '${KEYDIR}'/*.pub 2>/dev/null | awk '/^ssh-/{print}' | sort -u > '${auth}'"

  # Fix ownership if uid 1000 exists (jr)
  if sudo chroot "${mp}" id jr >/dev/null 2>&1; then
    sudo chroot "${mp}" chown -R jr:jr "/home/jr/.ssh" || true
  else
    # fallback: common Pi user uid/gid 1000
    sudo chown -R 1000:1000 "${sshdir}" || true
  fi
}

copy_toolkit_into_nvme() {
  local mp="$1"
  sudo mkdir -p "${mp}/opt"
  sudo rsync -a --exclude '.git/' --exclude 'keys/public/' "${SCRIPT_DIR}/" "${mp}/opt/jr-pi-toolkit/"

  # Install launcher on the NVMe image
  sudo mkdir -p "${mp}/usr/local/bin"
  sudo tee "${mp}/usr/local/bin/jr-toolkit" >/dev/null <<'LAUNCH'
#!/bin/bash
set -euo pipefail
exec /opt/jr-pi-toolkit/pi-menu.sh
LAUNCH
  sudo chmod 0755 "${mp}/usr/local/bin/jr-toolkit"
}

main() {
  banner
  echo "Detected root: ${ROOT_SRC}"
  require_sd_boot

  local nvme
  nvme="$(pick_nvme_disk)"

  echo
  echo "Target NVMe disk:"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS,MODEL,SERIAL "${nvme}" || true

  echo
  echo "Network check (recommended before flashing):"
  net_info
  echo
  echo "Public keys check:"
  require_keys_present
  echo "OK: found at least one .pub in ${KEYDIR}"

  echo
  echo "STEP A: Configure NVMe first-boot network (SD mode script)"
  pause
  run_if_exists "jr-set-nvme-network.sh"

  echo
  echo "STEP B: Golden SD first-run setup (tools/prep)"
  pause
  run_if_exists "jr-firstrun.sh"

  banner
  echo "NEXT STEP IS DESTRUCTIVE."
  echo "This will erase and reflash: ${nvme}"
  if ! confirm_one_word "FLASHNVME"; then
    die "Cancelled."
  fi

  echo
  echo "STEP C: Flash NVMe + seed identity"
  run_if_exists "flash-nvme-and-seed.sh"

  echo
  echo "Post-step: Mount NVMe root and make it headless-ready..."
  local mp
  mp="$(mount_nvme_root "${nvme}")"

  echo
  echo "Copy toolkit onto NVMe image..."
  copy_toolkit_into_nvme "${mp}"

  echo
  echo "Seed SSH authorized_keys onto NVMe image..."
  seed_keys_into_nvme "${mp}"

  echo
  echo "Unmount NVMe root..."
  sudo umount "${mp}" || true

  banner
  echo "DONE."
  echo
  echo "Next:"
  echo "1) Power off."
  echo "2) Remove the Golden SD."
  echo "3) Boot from NVMe."
  echo
  echo "Host-key warnings after imaging are normal. Fix on your PC with:"
  echo "  ssh-keygen -R <pi-ip>"
  echo
}

main "$@"
