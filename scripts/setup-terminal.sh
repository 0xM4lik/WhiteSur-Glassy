#!/bin/bash
set -e

echo "=== WhiteSur-Glassy Terminal Transparency Setup ==="

CONFIGURED=false

# 1. Setup Ptyxis (Fedora 40/41+ default GNOME terminal)
if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas | grep -q "org.gnome.Ptyxis"; then
    echo "-> Configuring Ptyxis terminal transparency (75% opacity)..."
    
    # Set dark interface style
    gsettings set org.gnome.Ptyxis interface-style "dark" 2>/dev/null || true

    # Get default profile UUID
    DEFAULT_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
    if [ -n "$DEFAULT_UUID" ] && [ "$DEFAULT_UUID" != "none" ]; then
        if command -v dconf >/dev/null 2>&1; then
            dconf write "/org/gnome/Ptyxis/Profiles/${DEFAULT_UUID}/opacity" 0.75
            echo "  [✓] Set opacity=0.75 for default Ptyxis profile: $DEFAULT_UUID"
            CONFIGURED=true
        fi
    fi

    # Set opacity on all other profiles in profile-uuids list
    PROFILE_LIST=$(gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null | tr -d "[]'" | tr ',' ' ')
    for p in $PROFILE_LIST; do
        if [ -n "$p" ] && command -v dconf >/dev/null 2>&1; then
            dconf write "/org/gnome/Ptyxis/Profiles/${p}/opacity" 0.75
            CONFIGURED=true
        fi
    done
fi

# 2. Setup GNOME Terminal (traditional GNOME terminal on Ubuntu/Debian/Arch)
if command -v gsettings >/dev/null 2>&1 && gsettings list-schemas | grep -q "org.gnome.Terminal.ProfilesList"; then
    echo "-> Configuring GNOME Terminal transparency (75% opacity / 25% transparency)..."
    
    DEFAULT_PROF=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
    if [ -n "$DEFAULT_PROF" ] && command -v dconf >/dev/null 2>&1; then
        dconf write "/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROF}/use-transparent-background" true
        dconf write "/org/gnome/terminal/legacy/profiles:/:${DEFAULT_PROF}/background-transparency-percent" 25
        echo "  [✓] Set 75% opacity for default GNOME Terminal profile: $DEFAULT_PROF"
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
fi

if [ "$CONFIGURED" = true ]; then
    echo "[✓] Terminal transparency (75%) configured successfully."
else
    echo "[!] No supported terminal schemas (Ptyxis or GNOME Terminal) found on this system."
fi
