#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBADWAITA_DIR="$SCRIPT_DIR/theme/libadwaita"
DEST_THEMES_DIR="$HOME/.themes"
XDG_THEMES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
DEST_ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
USER_EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

echo "Uninstalling WhiteSur-Glassy..."

# 1. Revert desktop themes and window controls
if command -v gsettings >/dev/null 2>&1; then
    echo "Reverting GTK and icon themes to default..."
    CURRENT_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "")
    case "$CURRENT_THEME" in
        "'WhiteSur-glassy'"|"'WhiteSur-Glassy-Transparent'"|"'WhiteSur-Glassy-Tinted'")
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
            ;;
    esac

    CURRENT_ICONS=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "")
    if [ "$CURRENT_ICONS" = "'WhiteSur'" ]; then
        gsettings set org.gnome.desktop.interface icon-theme "Adwaita" 2>/dev/null || true
    fi

    echo "Reverting window button layout..."
    gsettings set org.gnome.desktop.wm.preferences button-layout ":appmenu,close" 2>/dev/null || true
fi

# 2. Reset GNOME Shell theme in dconf
if command -v dconf >/dev/null 2>&1; then
    echo "Resetting GNOME Shell theme..."
    dconf write /org/gnome/shell/extensions/user-theme/name "''" 2>/dev/null || true
fi

# 3. Remove GTK theme files
for tname in "WhiteSur-Glassy-Transparent" "WhiteSur-Glassy-Tinted" "WhiteSur-glassy"; do
    if [ -d "$DEST_THEMES_DIR/$tname" ]; then
        echo "Removing $DEST_THEMES_DIR/$tname..."
        rm -rf "$DEST_THEMES_DIR/$tname"
    fi
    if [ -d "$XDG_THEMES_DIR/$tname" ]; then
        echo "Removing $XDG_THEMES_DIR/$tname..."
        rm -rf "$XDG_THEMES_DIR/$tname"
    fi
done

# 4. Remove Libadwaita overrides and restore backups
if [ -f "$LIBADWAITA_DIR/setup-libadwaita.sh" ]; then
    echo "Restoring GTK 4 / Libadwaita config..."
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" uninstall
fi

# 4b. Remove Flatpak overrides
if [ -f "$SCRIPT_DIR/scripts/setup-flatpak.sh" ]; then
    bash "$SCRIPT_DIR/scripts/setup-flatpak.sh" uninstall
fi

# 5. Revert terminal transparency back to opaque (1.0)
if command -v gsettings >/dev/null 2>&1 && command -v dconf >/dev/null 2>&1; then
    # Ptyxis
    if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis"; then
        echo "Resetting Ptyxis terminal opacity..."
        DEF_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'")
        [ -n "$DEF_UUID" ] && [ "$DEF_UUID" != "none" ] && dconf write "/org/gnome/Ptyxis/Profiles/${DEF_UUID}/opacity" 1.0 2>/dev/null || true
        ALL_UUIDS=$(gsettings get org.gnome.Ptyxis profile-uuids 2>/dev/null | tr -d "[]'" | tr ',' ' ')
        for u in $ALL_UUIDS; do
            [ -n "$u" ] && dconf write "/org/gnome/Ptyxis/Profiles/${u}/opacity" 1.0 2>/dev/null || true
        done
    fi

    # GNOME Terminal
    if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Terminal.ProfilesList"; then
        echo "Resetting GNOME Terminal opacity..."
        DEF_PROF=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
        if [ -n "$DEF_PROF" ]; then
            dconf write "/org/gnome/terminal/legacy/profiles:/:${DEF_PROF}/use-transparent-background" false 2>/dev/null || true
            dconf write "/org/gnome/terminal/legacy/profiles:/:${DEF_PROF}/background-transparency-percent" 0 2>/dev/null || true
        fi
    fi
fi

# 6. Restore original ~/.bashrc if a backup exists
LATEST_BASHRC_BAK=$(ls -t "$HOME"/.bashrc.pre-whitesur-*.bak 2>/dev/null | head -n 1 || true)
if [ -n "$LATEST_BASHRC_BAK" ] && [ -f "$LATEST_BASHRC_BAK" ]; then
    echo "Restoring ~/.bashrc from backup ($LATEST_BASHRC_BAK)..."
    cp -f "$LATEST_BASHRC_BAK" "$HOME/.bashrc"
fi

# 7. Reset extension configs in dconf
if command -v dconf >/dev/null 2>&1; then
    echo "Resetting extension configs in dconf..."
    dconf reset -f /org/gnome/shell/extensions/blur-my-shell/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/dash-to-dock/ 2>/dev/null || true
    dconf reset -f /org/gnome/shell/extensions/Logo-menu/ 2>/dev/null || true
fi

# 8. Clean up installed WhiteSur icons if present
if [ -d "$DEST_ICONS_DIR/WhiteSur" ]; then
    read -p "Remove installed WhiteSur icons from ~/.local/share/icons? [y/N]: " ans_icons || true
    case "$ans_icons" in
        [yY]*)
            echo "Removing WhiteSur icons..."
            rm -rf "$DEST_ICONS_DIR"/WhiteSur*
            ;;
    esac
fi

# 9. Clean up extensions installed into ~/.local/share/gnome-shell/extensions
EXT_LIST=("blur-my-shell@aunetx" "dash-to-dock@micxgx.gmail.com" "logomenu@aryan_k" "user-theme@gnome-shell-extensions.gcampax.github.com")
FOUND_EXTS=false
for ext in "${EXT_LIST[@]}"; do
    if [ -d "$USER_EXT_DIR/$ext" ]; then
        FOUND_EXTS=true
        break
    fi
done

if [ "$FOUND_EXTS" = true ]; then
    read -p "Remove installed GNOME extensions (Blur my Shell, Dash to Dock, Logo Menu, User Themes)? [y/N]: " ans_exts || true
    case "$ans_exts" in
        [yY]*)
            echo "Removing extensions from ~/.local/share/gnome-shell/extensions..."
            for ext in "${EXT_LIST[@]}"; do
                if [ -d "$USER_EXT_DIR/$ext" ]; then
                    rm -rf "$USER_EXT_DIR/$ext"
                fi
            done
            ;;
    esac
fi

# 10. Clean up gnome-rounded-blur library if installed
is_rounded_blur_installed() {
    if python3 -c "import gi; gi.require_version('Blur', '1.0'); from gi.repository import Blur" 2>/dev/null; then
        return 0
    fi
    if command -v rpm >/dev/null 2>&1 && rpm -q --quiet gnome-rounded-blur 2>/dev/null; then
        return 0
    fi
    if command -v pacman >/dev/null 2>&1 && pacman -Q gnome-rounded-blur >/dev/null 2>&1; then
        return 0
    fi
    if command -v dpkg >/dev/null 2>&1 && dpkg -s gnome-rounded-blur >/dev/null 2>&1; then
        return 0
    fi
    for p in /usr/lib64 /usr/lib /usr/lib/*-linux-gnu /usr/local/lib64 /usr/local/lib; do
        if [ -f "$p/girepository-1.0/Blur-1.0.typelib" ] && { [ -f "$p/libblur-effect-1.0.so" ] || [ -f "$p/libblur-effect-1.0.so.1" ]; }; then
            return 0
        fi
    done
    return 1
}

if is_rounded_blur_installed; then
    read -p "Uninstall gnome-rounded-blur library? [y/N]: " ans_blur || true
    case "$ans_blur" in
        [yY]*)
            echo "Uninstalling gnome-rounded-blur..."
            if command -v rpm >/dev/null 2>&1 && rpm -q --quiet gnome-rounded-blur 2>/dev/null; then
                if command -v rpm-ostree >/dev/null 2>&1 && { [ -d /run/ostree-booted ] || [ -f /run/ostree-booted ]; }; then
                    rpm-ostree uninstall gnome-rounded-blur 2>/dev/null || true
                elif command -v dnf >/dev/null 2>&1; then
                    if [ "$EUID" -eq 0 ]; then
                        dnf remove -y gnome-rounded-blur 2>/dev/null || true
                    else
                        sudo dnf remove -y gnome-rounded-blur 2>/dev/null || true
                    fi
                fi
            elif command -v pacman >/dev/null 2>&1 && pacman -Q gnome-rounded-blur >/dev/null 2>&1; then
                if [ "$EUID" -eq 0 ]; then
                    pacman -R --noconfirm gnome-rounded-blur 2>/dev/null || true
                else
                    sudo pacman -R --noconfirm gnome-rounded-blur 2>/dev/null || true
                fi
            else
                curl -fsSL https://raw.githubusercontent.com/aunetx/blur-my-shell/master/scripts/rounded_blur_build.sh | bash -s -- -u 2>/dev/null || true
            fi
            ;;
    esac
fi

echo "Done. WhiteSur-Glassy has been uninstalled."
