#!/usr/bin/env bash
set -euo pipefail

# install-shortcut.sh
# Creates a global 'pi-factory' command

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="/usr/local/bin/pi-factory"

echo "Installing global shortcut..."
echo "#!/bin/bash" > "$TARGET_BIN"
echo "cd \"$BASE_DIR\"" >> "$TARGET_BIN"
echo "sudo bash main.sh" >> "$TARGET_BIN"

chmod +x "$TARGET_BIN"

echo "Done! You can now run the tool from anywhere by typing:"
echo "  pi-factory"
