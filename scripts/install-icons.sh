#!/bin/bash
set -e

DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
mkdir -p "$DEST_DIR"

if [ -d "$DEST_DIR/WhiteSur" ] || [ -d "/usr/share/icons/WhiteSur" ]; then
    echo "WhiteSur icons are already installed."
else
    echo "Installing WhiteSur icons..."
    if [ -d "$HOME/Tweaks/WhiteSur-icon-theme" ] && [ -f "$HOME/Tweaks/WhiteSur-icon-theme/install.sh" ]; then
        bash "$HOME/Tweaks/WhiteSur-icon-theme/install.sh" -d "$DEST_DIR" -t default
    elif command -v git >/dev/null 2>&1; then
        TMP_ICON_DIR=$(mktemp -d)
        cleanup() {
            rm -rf "$TMP_ICON_DIR"
        }
        trap cleanup EXIT
        git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$TMP_ICON_DIR"
        bash "$TMP_ICON_DIR/install.sh" -d "$DEST_DIR" -t default
    else
        echo "Git is required to download WhiteSur icons."
        echo "Please install git or clone https://github.com/vinceliuice/WhiteSur-icon-theme manually."
        exit 1
    fi
fi

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface icon-theme "WhiteSur" 2>/dev/null || true
fi

echo "WhiteSur icons installed and selected."
