#!/usr/bin/env bash
set -euo pipefail

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"

TOOLKIT_SD="/home/jr/pi-toolkit"
TOOLKIT_NVME="/opt/jr-pi-toolkit"

# BOOT MODE MUST BE BASED ON ROOT DEVICE ONLY (leftover dirs shouldn't matter)
if [[ "$ROOT_SRC" == /dev/mmcblk* ]]; then
  BOOT_MODE="SD"
  TOOLKIT_ROOT="$TOOLKIT_SD"
else
  BOOT_MODE="NVME"
  TOOLKIT_ROOT="$TOOLKIT_NVME"
fi

pause() { read -rp "Press Enter to return to menu..." _; }

confirm_phrase() {
  local phrase="$1"
  echo
  echo "CONFIRM REQUIRED"
  echo "Type exactly: $phrase"
  read -rp "> " typed
  [[ "${typed:-}" == "$phrase" ]]
}
menu_line() {
  local n="$1"
  local text="$2"
  local tag="${3:-}"

  local cols
  cols="$(tput cols 2>/dev/null || echo 80)"
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80

  local left="${n})  ${text}"

  if [[ -n "$tag" ]]; then
    local tag_col=$(( cols - ${#tag} - 1 ))
    (( tag_col < 10 )) && tag_col=10

    local max_left=$(( tag_col ))
    if (( ${#left} > max_left )); then
      if (( max_left > 6 )); then
        left="${left:0:$((max_left-3))}..."
      else
        left="${left:0:$max_left}"
      fi
    fi

    printf "%-*s %s\n" "$tag_col" "$left" "$tag"
  else
    printf "%s\n" "$left"
  fi
}

kv_line() {
  local key="$1"
  local val="${2-}"

  # trim leading/trailing whitespace (protects against weird spacing)
  val="${val#"${val%%[![:space:]]*}"}"
  val="${val%"${val##*[![:space:]]}"}"

  # fixed key column so values line up cleanly
  printf "%-14s %s\n" "$key" "$val"
}
while true; do
  clear || true
  echo "==============================================================="
  echo " JR PI TOOLKIT - GOLDEN SD / NVMe TOOLKIT (HEADLESS SAFE)"
  echo "==============================================================="
  echo
    printf "%-13s %s
" "Detected root:" "${ROOT_SRC}"
    printf "%-13s %s
" "Toolkit root:"  "${TOOLKIT_ROOT}"
    case "${BOOT_MODE:-}" in
      SD)   printf "%-13s %s
" "Mode:" "SD (installer)";;
      NVME) printf "%-13s %s
" "Mode:" "NVMe (runtime)";;
      *)    printf "%-13s %s
" "Mode:" "UNKNOWN";;
    esac
    if [[ -x /home/jr/pi-apps/pi-apps || -x /home/jr/pi-apps/updater ]]; then
      printf "%-13s %s
" "Pi-Apps:" "installed (/home/jr/pi-apps)"
    else
      printf "%-13s %s
" "Pi-Apps:" "not installed"
    fi
    echo

  echo "Menu"
  echo "----"
  menu_line 0  "Exit"
  menu_line 1  "Set NVMe first-boot network (Ethernet/Wi-Fi)"                 "[SD only]"
  menu_line 2  "First-run setup (Golden SD prep, networking, tools)"          "[SD only]"
  menu_line 3  "Flash NVMe + seed identity (DESTRUCTIVE)"                     "[SD only]"
  menu_line 4  "Re-run provisioning"                                          "[NVMe only]"
  menu_line 5  "Install Pi-Apps (menu-driven)"                                "[NVMe only]"
  menu_line 6  "Health Check (log to /var/log/jr-pi-toolkit)"                 "[NVMe only]"
  menu_line 7  "Backup / Imaging (SD image, sanitize)"                        "[NVMe only]"
    menu_line 8  "Status Dashboard (jr-status.sh)"                              "[status]"
    menu_line 9  "Help / Checklist (what to do, in what order)"                  "[help]"
  menu_line 10 "Re-seed identity from Golden SD (requires SD inserted)"       "[NVMe only]"
  menu_line 11 "Power (reboot/poweroff/ssh)"                                  "[ALL]"
  menu_line 12 "Update toolkit from GitHub (fast-forward only)"               "[ALL]"
  menu_line 13 "Seed SSH keys for jr from toolkit (public keys)"              "[ALL]"
    menu_line 14 "Guided NVMe build from Golden SD (end-to-end)"           "[SD only]"
    menu_line 15 "Cases: Pironman / Argon installers (opt-in)"
    menu_line 16 "Doctor / Preflight (sanity checks)"                               "[ALL]"                  "[ALL]"
  echo

  read -rp "Select: " choice

  if [[ "${choice:-}" == "0" ]]; then
    echo "Exiting JR Pi Toolkit."
    exit 0
  fi

  case "${choice:-}" in
    1)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-set-nvme-network.sh"
      pause
      ;;
    2)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-firstrun.sh"
      pause
      ;;
    3)
      [[ "$BOOT_MODE" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
      if ! confirm_phrase "FLASH_NVME_ERASE_ALL"; then
        echo "Canceled."
        pause
        continue
      fi
      sudo "$TOOLKIT_ROOT/flash-nvme-and-seed.sh"
      pause
      ;;
    4)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      if ! confirm_phrase "RUN_PROVISION_ON_NVME"; then
        echo "Canceled."
        pause
        continue
      fi
      sudo "$TOOLKIT_ROOT/jr-provision.sh"
      pause
      ;;
    5)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-install-pi-apps.sh" ]] || { echo "ERROR: Missing jr-install-pi-apps.sh"; pause; continue; }
      sudo -u jr -H bash -lc "$TOOLKIT_ROOT/jr-install-pi-apps.sh"
      pause
      ;;
    6)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-health-check.sh" ]] || { echo "ERROR: Missing jr-health-check.sh"; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-health-check.sh"
      pause
      ;;
    7)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-backup-menu.sh" ]] || { echo "ERROR: Missing jr-backup-menu.sh"; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-backup-menu.sh"
      pause
      ;;
    8)
      [[ -x "$TOOLKIT_ROOT/jr-status.sh" ]] || { echo "ERROR: Missing jr-status.sh"; pause; continue; }
      "$TOOLKIT_ROOT/jr-status.sh" || true
      pause
      ;;
    9)
      echo
      echo "CHECKLIST (Golden SD -> NVMe, headless)"
      echo "1) Boot from Golden SD (installer only)."
      echo "2) Run Option 1 (Set NVMe first-boot network)."
      echo "3) Run Option 2 (First-run setup / Golden SD prep)."
      echo "4) Run Option 3 (Flash NVMe + seed identity)."
      echo "5) Power off, remove SD."
      echo "6) Boot from NVMe once. SSH should come up as jr with keys."
      echo "7) From NVMe, run provisioning only when YOU choose (Option 4)."
      echo "8) Pi-Apps and workload installs are menu items, not automatic."
      echo
      echo "SSH keys for BOTH PCs:"
      echo " - Put public keys into: ${TOOLKIT_ROOT}/keys/public/"
      echo " - Then run Option 13"
      echo
      pause
      ;;
    10)
      [[ "$BOOT_MODE" == "NVME" ]] || { echo "ERROR: NVMe only."; pause; continue; }
      [[ -x "$TOOLKIT_ROOT/jr-reseed-from-golden-sd.sh" ]] || { echo "ERROR: Missing jr-reseed-from-golden-sd.sh"; pause; continue; }
      "$TOOLKIT_ROOT/jr-reseed-from-golden-sd.sh" || true
      pause
      ;;
    11)
      [[ -x "$TOOLKIT_ROOT/jr-power-menu.sh" ]] || { echo "ERROR: Missing jr-power-menu.sh"; pause; continue; }
      "$TOOLKIT_ROOT/jr-power-menu.sh" || true
      ;;
    12)
      [[ -x "$TOOLKIT_ROOT/jr-self-update.sh" ]] || { echo "ERROR: Missing jr-self-update.sh"; pause; continue; }
      "$TOOLKIT_ROOT/jr-self-update.sh" || true
      ;;
    13)
      [[ -x "$TOOLKIT_ROOT/jr-seed-ssh-keys.sh" ]] || { echo "ERROR: Missing jr-seed-ssh-keys.sh"; pause; continue; }
      sudo "$TOOLKIT_ROOT/jr-seed-ssh-keys.sh" || true
      pause
      ;;
  14)
    [[ "" == "SD" ]] || { echo "ERROR: SD only."; pause; continue; }
    [[ -x "$TOOLKIT_ROOT/jr-golden-sd-build-nvme.sh" ]] || { echo "ERROR: Missing jr-golden-sd-build-nvme.sh"; pause; continue; }
    sudo "$TOOLKIT_ROOT/jr-golden-sd-build-nvme.sh"
    pause
    ;;

  15)
    [[ -x "$TOOLKIT_ROOT/jr-cases-menu.sh" ]] || { echo "ERROR: Missing jr-cases-menu.sh"; pause; continue; }
    bash "$TOOLKIT_ROOT/jr-cases-menu.sh"
    pause
    ;;


    *)
      echo "Invalid selection."
      sleep 1
      ;;
  esac
done
