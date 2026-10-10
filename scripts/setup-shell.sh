#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG="$SCRIPT_DIR/../configs/shell/bashrc"
TARGET_BASHRC="$HOME/.bashrc"

echo "Setting up shell configuration..."

if [ ! -f "$SHELL_CONFIG" ]; then
    echo "Error: Config file not found at $SHELL_CONFIG"
    exit 1
fi

# Install Starship prompt if missing
if ! command -v starship >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/starship" ]; then
    echo "Installing Starship prompt..."
    mkdir -p "$HOME/.local/bin"
    if command -v curl >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    else
        echo "Could not download Starship automatically (curl or wget required)."
    fi
else
    echo "Starship prompt is already installed."
fi

# Backup existing .bashrc
if [ -f "$TARGET_BASHRC" ]; then
    BACKUP_BASHRC="$HOME/.bashrc.pre-whitesur-$(date +%Y%m%d%H%M%S).bak"
    cp -f "$TARGET_BASHRC" "$BACKUP_BASHRC"
    echo "Saved backup of existing .bashrc to $BACKUP_BASHRC"
fi

cp -f "$SHELL_CONFIG" "$TARGET_BASHRC"
echo "Updated ~/.bashrc"
echo "To load changes in your current terminal, run: source ~/.bashrc"
