#!/bin/bash
set -e

ACTION="${1:-install}"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CSS="$SCRIPT_DIR/gtk-WhiteSur-glassy.css"

if [ "$ACTION" = "install" ]; then
    echo "Setting up GTK 4 / Libadwaita theme..."
    mkdir -p "$TARGET_DIR"

    # Backup existing gtk.css if not already backed up
    if [ -f "$TARGET_DIR/gtk.css" ] && [ ! -L "$TARGET_DIR/gtk.css" ]; then
        cp -f "$TARGET_DIR/gtk.css" "$TARGET_DIR/gtk.css.bak"
    fi
    if [ -f "$TARGET_DIR/gtk-dark.css" ] && [ ! -L "$TARGET_DIR/gtk-dark.css" ]; then
        cp -f "$TARGET_DIR/gtk-dark.css" "$TARGET_DIR/gtk-dark.css.bak"
    fi

    cp -f "$SOURCE_CSS" "$TARGET_DIR/gtk-WhiteSur-glassy.css"

    # Copy window controls assets
    if [ -d "$SCRIPT_DIR/windows-assets" ]; then
        rm -rf "$TARGET_DIR/windows-assets"
        cp -rf "$SCRIPT_DIR/windows-assets" "$TARGET_DIR/"
    elif [ ! -d "$TARGET_DIR/windows-assets" ]; then
        if [ -d "$HOME/Tweaks/WhiteSur-gtk-theme/src/assets/gtk/windows-assets/titlebutton" ]; then
            cp -rf "$HOME/Tweaks/WhiteSur-gtk-theme/src/assets/gtk/windows-assets/titlebutton" "$TARGET_DIR/windows-assets"
        elif command -v git >/dev/null 2>&1; then
            TMP_GTK=$(mktemp -d)
            if git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$TMP_GTK" 2>/dev/null; then
                if [ -d "$TMP_GTK/src/assets/gtk/windows-assets/titlebutton" ]; then
                    cp -rf "$TMP_GTK/src/assets/gtk/windows-assets/titlebutton" "$TARGET_DIR/windows-assets"
                fi
            fi
            rm -rf "$TMP_GTK"
        fi
    fi

    if [ -f "$SCRIPT_DIR/gtk-WhiteSur-Dark.css" ]; then
        cp -f "$SCRIPT_DIR/gtk-WhiteSur-Dark.css" "$TARGET_DIR/gtk-WhiteSur-Dark.css"
    elif [ -f "$TARGET_DIR/gtk-Dark.css" ] && [ ! -f "$TARGET_DIR/gtk-WhiteSur-Dark.css" ]; then
        cp -f "$TARGET_DIR/gtk-Dark.css" "$TARGET_DIR/gtk-WhiteSur-Dark.css"
    fi

    # Use relative symlinks so they resolve properly inside Flatpak sandboxes
    # where ~/.config/gtk-4.0 is mounted at ~/.var/app/<app-id>/config/gtk-4.0
    ln -sf "gtk-WhiteSur-glassy.css" "$TARGET_DIR/gtk.css"
    ln -sf "gtk-WhiteSur-glassy.css" "$TARGET_DIR/gtk-dark.css"
    echo "Libadwaita theme applied."

elif [ "$ACTION" = "uninstall" ]; then
    echo "Removing Libadwaita theme overrides..."
    rm -f "$TARGET_DIR/gtk-WhiteSur-glassy.css"
    rm -f "$TARGET_DIR/gtk-WhiteSur-Dark.css"
    rm -rf "$TARGET_DIR/windows-assets"
    
    if [ -f "$TARGET_DIR/gtk.css.bak" ]; then
        mv -f "$TARGET_DIR/gtk.css.bak" "$TARGET_DIR/gtk.css"
    else
        rm -f "$TARGET_DIR/gtk.css"
    fi

    if [ -f "$TARGET_DIR/gtk-dark.css.bak" ]; then
        mv -f "$TARGET_DIR/gtk-dark.css.bak" "$TARGET_DIR/gtk-dark.css"
    else
        rm -f "$TARGET_DIR/gtk-dark.css"
    fi
    echo "Restored previous Libadwaita config."
else
    echo "Usage: $0 [install|uninstall]"
    exit 1
fi
