#!/bin/bash
set -e

echo "Setting terminal transparency to 75%..."

CONFIGURED=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PALETTE_FILE="$SCRIPT_DIR/../configs/terminal/WhiteSur-Glassy.palette"
PTYXIS_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/org.gnome.Ptyxis/palettes"

# 1. Ptyxis (Fedora default)
if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis"; then
    gsettings set org.gnome.Ptyxis interface-style "dark" 2>/dev/null || true

    if [ -f "$PALETTE_FILE" ]; then
        mkdir -p "$PTYXIS_DATA_DIR"
        cp -f "$PALETTE_FILE" "$PTYXIS_DATA_DIR/WhiteSur-Glassy.palette"
    fi

    DEFAULT_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
    if [ -n "$DEFAULT_UUID" ] && [ "$DEFAULT_UUID" != "none" ]; then
        if command -v dconf >/dev/null 2>&1; then
            dconf write "/org/gnome/Ptyxis/Profiles/${DEFAULT_UUID}/opacity" 0.75
            dconf write "/org/gnome/Ptyxis/Profiles/${DEFAULT_UUID}/palette" "'WhiteSur-Glassy'"
            CONFIGURED=true
        fi
    fi

    PROFILE_LIST=$(gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null | tr -d "[]'" | tr ',' ' ')
    for p in $PROFILE_LIST; do
        if [ -n "$p" ] && command -v dconf >/dev/null 2>&1; then
            dconf write "/org/gnome/Ptyxis/Profiles/${p}/opacity" 0.75
            dconf write "/org/gnome/Ptyxis/Profiles/${p}/palette" "'WhiteSur-Glassy'"
            CONFIGURED=true
        fi
    done
    echo "Ptyxis configured."
fi

# 2. GNOME Terminal
if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Terminal.ProfilesList"; then
    DEFAULT_PROF=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
    if [ -n "$DEFAULT_PROF" ] && command -v dconf >/dev/null 2>&1; then
        dconf write "/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROF}/use-transparent-background" true
        dconf write "/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROF}/background-transparency-percent" 25
        CONFIGURED=true
    fi

    ALL_PROFS=$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null | tr -d "[]'" | tr ',' ' ')
    for gp in $ALL_PROFS; do
        if [ -n "$gp" ] && command -v dconf >/dev/null 2>&1; then
            dconf write "/org/gnome/terminal/legacy/profiles:/:${gp}/use-transparent-background" true
            dconf write "/org/gnome/terminal/legacy/profiles:/:${gp}/background-transparency-percent" 25
            CONFIGURED=true
        fi
    done
    echo "GNOME Terminal configured."
fi

if [ "$CONFIGURED" = true ]; then
    echo "Terminal transparency set."
else
    echo "No supported terminal profiles found to configure."
fi
