#!/bin/bash
set -e

echo "JR Pi Toolkit"
echo "=============="
echo "1) First-run setup"
echo "2) Flash NVMe from image"
echo "3) Exit"
read -rp "Select: " choice

case "$choice" in
  1) ./jr-firstrun.sh ;;
  2) ./flash-nvme.sh ;;
  *) exit 0 ;;
esac
