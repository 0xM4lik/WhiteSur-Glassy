#!/bin/bash
set -e

ACTION="${1:-install}"
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CSS="$SCRIPT_DIR/gtk-WhiteSur-glassy.css"

if [ "$ACTION" = "install" ]; then
    echo "Installing WhiteSur-Glassy Libadwaita overrides..."
    mkdir -p "$TARGET_DIR"

    # Backup existing gtk.css if not already backed up
    if [ -f "$TARGET_DIR/gtk.css" ] && [ ! -L "$TARGET_DIR/gtk.css" ]; then
        cp -f "$TARGET_DIR/gtk.css" "$TARGET_DIR/gtk.css.bak"
        echo "Backed up existing gtk.css to gtk.css.bak"
    fi
    if [ -f "$TARGET_DIR/gtk-dark.css" ] && [ ! -L "$TARGET_DIR/gtk-dark.css" ]; then
        cp -f "$TARGET_DIR/gtk-dark.css" "$TARGET_DIR/gtk-dark.css.bak"
        echo "Backed up existing gtk-dark.css to gtk-dark.css.bak"
    fi

    # Copy the glassy stylesheet into the config directory
    cp -f "$SOURCE_CSS" "$TARGET_DIR/gtk-WhiteSur-glassy.css"

    # Symlink gtk.css and gtk-dark.css
    ln -sf "$TARGET_DIR/gtk-WhiteSur-glassy.css" "$TARGET_DIR/gtk.css"
    ln -sf "$TARGET_DIR/gtk-WhiteSur-glassy.css" "$TARGET_DIR/gtk-dark.css"
    echo "Libadwaita glassy theme active in $TARGET_DIR."

elif [ "$ACTION" = "uninstall" ]; then
    echo "Removing WhiteSur-Glassy Libadwaita overrides..."
    rm -f "$TARGET_DIR/gtk-WhiteSur-glassy.css"
    
    # Restore backups if present
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
    echo "Libadwaita overrides restored."
else
    echo "Usage: $0 [install|uninstall]"
    exit 1
fi
