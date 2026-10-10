#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBADWAITA_DIR="$SCRIPT_DIR/theme/libadwaita"
DEST_THEMES_DIR="${XDG_DATA_HOME:-$HOME/.themes}"

echo "=== WhiteSur-Glassy Uninstaller ==="

# 1. Reset GTK theme & window buttons to default if WhiteSur-glassy is active
if command -v gsettings >/dev/null 2>&1; then
    CURRENT_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "")
    if [ "$CURRENT_THEME" = "'WhiteSur-glassy'" ]; then
        echo "-> Reverting GTK theme to default..."
        gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
    fi

    echo "-> Reverting window controls button layout..."
    gsettings set org.gnome.desktop.wm.preferences button-layout ":appmenu,close" 2>/dev/null || true
fi

# 2. Remove GTK Theme
if [ -d "$DEST_THEMES_DIR/WhiteSur-glassy" ]; then
    echo "-> Removing $DEST_THEMES_DIR/WhiteSur-glassy..."
    rm -rf "$DEST_THEMES_DIR/WhiteSur-glassy"
fi

# 3. Revert Libadwaita overrides
if [ -f "$LIBADWAITA_DIR/setup-libadwaita.sh" ]; then
    echo "-> Restoring Libadwaita overrides..."
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" uninstall
fi

# 4. Restore YouTube Music Flatpak
if [ -f "$SCRIPT_DIR/apps/youtube-music/restore-youtube-music.sh" ]; then
    if [ -d "$HOME/.local/share/youtube-music-glassy" ]; then
        echo "-> Restoring YouTube Music Flatpak..."
        bash "$SCRIPT_DIR/apps/youtube-music/restore-youtube-music.sh"
    fi
fi

echo ""
echo "=== WhiteSur-Glassy uninstalled successfully. ==="
