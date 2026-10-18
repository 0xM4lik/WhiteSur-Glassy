#!/bin/bash
set -e

ACTION="${1:-install}"
DEST_ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
OVERRIDE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/overrides"
OVERRIDE_FILE="$OVERRIDE_DIR/global"

if [ "$ACTION" = "install" ]; then
    echo "Configuring Flatpak theme overrides..."

    if command -v flatpak >/dev/null 2>&1; then
        flatpak override --user --filesystem=xdg-config/gtk-4.0:ro
        flatpak override --user --filesystem=xdg-config/gtk-3.0:ro
        flatpak override --user --filesystem=xdg-data/themes:ro
        flatpak override --user --filesystem=~/.themes:ro
        flatpak override --user --filesystem=xdg-data/icons:ro
        flatpak override --user --filesystem=~/.icons:ro
        flatpak override --user --env=GTK_THEME=WhiteSur-glassy

        if [ -d "$DEST_ICONS_DIR/WhiteSur" ] || [ -d "/usr/share/icons/WhiteSur" ] || [ -d "$HOME/.icons/WhiteSur" ]; then
            flatpak override --user --env=ICON_THEME=WhiteSur
        fi

        # Ensure gtk.css and gtk-dark.css in ~/.config/gtk-4.0 use relative symlinks
        # so they resolve cleanly inside Flatpak sandboxes
        GTK4_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"
        if [ -f "$GTK4_DIR/gtk-WhiteSur-glassy.css" ]; then
            ln -sf "gtk-WhiteSur-glassy.css" "$GTK4_DIR/gtk.css"
            ln -sf "gtk-WhiteSur-glassy.css" "$GTK4_DIR/gtk-dark.css"
        fi

        echo "Flatpak theme overrides applied."
    else
        echo "Flatpak is not installed; skipping Flatpak overrides."
    fi

elif [ "$ACTION" = "uninstall" ]; then
    if [ -f "$OVERRIDE_FILE" ]; then
        echo "Removing Flatpak theme overrides..."
        if command -v python3 >/dev/null 2>&1; then
            python3 - "$OVERRIDE_FILE" << 'PYEOF'
import configparser
import os
import sys

override_file = sys.argv[1]
cfg = configparser.ConfigParser(interpolation=None)
cfg.optionxform = str
cfg.read(override_file)

target_fs = {
    "xdg-config/gtk-4.0:ro", "xdg-config/gtk-4.0", "!xdg-config/gtk-4.0",
    "xdg-config/gtk-3.0:ro", "xdg-config/gtk-3.0", "!xdg-config/gtk-3.0",
    "xdg-data/themes:ro", "xdg-data/themes", "!xdg-data/themes",
    "~/.themes:ro", "~/.themes", "!~/.themes",
    "xdg-data/icons:ro", "xdg-data/icons", "!xdg-data/icons",
    "~/.icons:ro", "~/.icons", "!~/.icons",
}

if cfg.has_section("Context"):
    if cfg.has_option("Context", "filesystems"):
        raw = cfg.get("Context", "filesystems")
        items = [x for x in raw.split(";") if x and x not in target_fs]
        if items:
            cfg.set("Context", "filesystems", ";".join(items) + ";")
        else:
            cfg.remove_option("Context", "filesystems")
    if cfg.has_option("Context", "unset-environment"):
        raw_unset = cfg.get("Context", "unset-environment")
        items_unset = [x for x in raw_unset.split(";") if x and x not in {"GTK_THEME", "ICON_THEME"}]
        if items_unset:
            cfg.set("Context", "unset-environment", ";".join(items_unset) + ";")
        else:
            cfg.remove_option("Context", "unset-environment")
    if not cfg.options("Context"):
        cfg.remove_section("Context")

if cfg.has_section("Environment"):
    if cfg.has_option("Environment", "GTK_THEME") and cfg.get("Environment", "GTK_THEME") in {"WhiteSur-glassy", ""}:
        cfg.remove_option("Environment", "GTK_THEME")
    if cfg.has_option("Environment", "ICON_THEME") and cfg.get("Environment", "ICON_THEME") in {"WhiteSur", ""}:
        cfg.remove_option("Environment", "ICON_THEME")
    if not cfg.options("Environment"):
        cfg.remove_section("Environment")

if cfg.sections():
    with open(override_file, "w") as f:
        cfg.write(f, space_around_delimiters=False)
else:
    os.remove(override_file)
PYEOF
        else
            rm -f "$OVERRIDE_FILE"
        fi
        echo "Flatpak theme overrides removed."
    fi
else
    echo "Usage: $0 [install|uninstall]"
    exit 1
fi
