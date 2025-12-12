#!/bin/bash
set -e

echo "Running first-run setup..."

sudo apt update
sudo apt install -y git curl vim

echo "First-run complete."
echo "Marking first-run complete"
sudo mkdir -p /var/lib/jr-toolkit
sudo touch /var/lib/jr-toolkit/first-run.done
