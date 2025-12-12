#!/bin/bash
set -e

echo "Running first-run setup..."

sudo apt update
sudo apt install -y git curl vim

echo "First-run complete."
