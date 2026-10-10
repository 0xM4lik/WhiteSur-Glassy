#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG="$SCRIPT_DIR/../configs/shell/bashrc"
TARGET_BASHRC="$HOME/.bashrc"

echo "=== WhiteSur-Glassy Shell Configuration Setup ==="

if [ ! -f "$SHELL_CONFIG" ]; then
    echo "Error: Shell configuration template not found at $SHELL_CONFIG"
    exit 1
fi

if [ -f "$TARGET_BASHRC" ]; then
    BACKUP_BASHRC="$HOME/.bashrc.pre-whitesur-$(date +%Y%m%d%H%M%S).bak"
    cp -f "$TARGET_BASHRC" "$BACKUP_BASHRC"
    echo "-> Backed up existing ~/.bashrc to: $BACKUP_BASHRC"
fi

# Check if starship is installed
if ! command -v starship >/dev/null 2>&1; then
    echo "Notice: 'starship' prompt is not currently installed."
    echo "        Install starship anytime via: curl -sS https://starship.rs/install.sh | sh"
fi

# Check if fastfetch is installed
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Notice: 'fastfetch' is not installed."
    echo "        Fedora: sudo dnf install fastfetch | Ubuntu: sudo apt install fastfetch"
fi

cp -f "$SHELL_CONFIG" "$TARGET_BASHRC"
echo "[✓] Sleek WhiteSur-Glassy shell configuration installed to ~/.bashrc"
echo "    Reload in your current terminal via: source ~/.bashrc"
