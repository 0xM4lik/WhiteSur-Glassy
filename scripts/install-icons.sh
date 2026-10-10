#!/bin/bash
set -e

echo "=== WhiteSur Apple Icon Theme Installer ==="

DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
mkdir -p "$DEST_DIR"

if [ -d "$DEST_DIR/WhiteSur" ] || [ -d "/usr/share/icons/WhiteSur" ]; then
    echo "-> WhiteSur icon theme is already installed."
else
    echo "-> Installing WhiteSur icon theme..."
    if [ -d "$HOME/Tweaks/WhiteSur-icon-theme" ] && [ -f "$HOME/Tweaks/WhiteSur-icon-theme/install.sh" ]; then
        echo "  (Found local repository in $HOME/Tweaks/WhiteSur-icon-theme)"
        bash "$HOME/Tweaks/WhiteSur-icon-theme/install.sh" -d "$DEST_DIR" -t default
    elif command -v git >/dev/null 2>&1; then
        echo "  (Fetching WhiteSur-icon-theme from GitHub...)"
        TMP_ICON_DIR=$(mktemp -d)
        cleanup() {
            rm -rf "$TMP_ICON_DIR"
        }
        trap cleanup EXIT
        git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$TMP_ICON_DIR"
        bash "$TMP_ICON_DIR/install.sh" -d "$DEST_DIR" -t default
    else
        echo "Error: 'git' is required to download WhiteSur-icon-theme."
        echo "Install git or manually clone: https://github.com/vinceliuice/WhiteSur-icon-theme"
        exit 1
    fi
fi

if command -v gsettings >/dev/null 2>&1; then
    echo "-> Setting GNOME icon theme to WhiteSur..."
    gsettings set org.gnome.desktop.interface icon-theme "WhiteSur" 2>/dev/null || true
fi

echo "[✓] WhiteSur icon theme ready and activated."
