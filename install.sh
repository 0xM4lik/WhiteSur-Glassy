#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/theme/WhiteSur-glassy"
LIBADWAITA_DIR="$SCRIPT_DIR/theme/libadwaita"
DEST_THEMES_DIR="${XDG_DATA_HOME:-$HOME/.themes}"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"

INSTALL_THEME=false
INSTALL_LIBADWAITA=false
INSTALL_ICONS=false
INSTALL_EXTENSIONS=false
INSTALL_ROUNDED_BLUR=false
INSTALL_TERMINAL=false
INSTALL_SHELL=false
INSTALL_CONFIGS=false

check_tool() {
    command -v "$1" >/dev/null 2>&1
}

HAS_PYTHON=false
HAS_GNOME_EXT=false
HAS_ROUNDED_BLUR=false
HAS_DCONF=false
HAS_ICONS=false
HAS_PTYXIS=false
HAS_GNOME_TERM=false

check_tool python3 && HAS_PYTHON=true
check_tool gnome-extensions && HAS_GNOME_EXT=true
check_tool dconf && HAS_DCONF=true

if [ -d "$HOME/.local/share/icons/WhiteSur" ] || [ -d "/usr/share/icons/WhiteSur" ]; then
    HAS_ICONS=true
fi

if python3 -c "import gi; gi.require_version('Blur', '1.0'); from gi.repository import Blur" 2>/dev/null; then
    HAS_ROUNDED_BLUR=true
elif command -v rpm >/dev/null 2>&1 && rpm -q --quiet gnome-rounded-blur 2>/dev/null; then
    HAS_ROUNDED_BLUR=true
elif command -v pacman >/dev/null 2>&1 && pacman -Q gnome-rounded-blur >/dev/null 2>&1; then
    HAS_ROUNDED_BLUR=true
elif command -v dpkg >/dev/null 2>&1 && dpkg -s gnome-rounded-blur >/dev/null 2>&1; then
    HAS_ROUNDED_BLUR=true
else
    for p in /usr/lib64 /usr/lib /usr/lib/*-linux-gnu /usr/local/lib64 /usr/local/lib; do
        if [ -f "$p/girepository-1.0/Blur-1.0.typelib" ] && { [ -f "$p/libblur-effect-1.0.so" ] || [ -f "$p/libblur-effect-1.0.so.1" ]; }; then
            HAS_ROUNDED_BLUR=true
            break
        fi
    done
fi

if check_tool gsettings; then
    gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis" && HAS_PTYXIS=true
    gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Terminal.ProfilesList" && HAS_GNOME_TERM=true
fi

show_help() {
    cat << HELP_EOF
Usage: ./install.sh [OPTIONS]

Options:
  --all            Install everything (themes, window buttons, icons, extensions, rounded blur library, terminal, shell, configs)
  --theme          Install GTK 3/4 theme, Libadwaita overrides, and left-side window buttons
  --icons          Install WhiteSur icons
  --extensions     Install GNOME extensions and gnome-rounded-blur library
  --rounded-blur   Install gnome-rounded-blur library for Blur my Shell rounded corners
  --terminal       Set terminal transparency to 75% (Ptyxis and GNOME Terminal)
  --shell          Setup .bashrc and install Starship prompt
  --configs        Apply recommended extension and terminal settings
  --check          Check system dependencies
  --help, -h       Show this help message

Running without arguments starts interactive setup.
HELP_EOF
}

print_dependency_status() {
    echo "Checking dependencies:"
    if [ "$HAS_PYTHON" = true ]; then
        echo "  - Python 3: found"
    else
        echo "  - Python 3: not found"
    fi

    if [ "$HAS_GNOME_EXT" = true ]; then
        echo "  - gnome-extensions: found"
    else
        echo "  - gnome-extensions: not found (needed to install extensions automatically)"
    fi

    if [ "$HAS_ROUNDED_BLUR" = true ]; then
        echo "  - gnome-rounded-blur: installed"
    else
        echo "  - gnome-rounded-blur: not installed (needed for Blur my Shell rounded dynamic corners)"
    fi

    if [ "$HAS_ICONS" = true ]; then
        echo "  - WhiteSur icons: installed"
    else
        echo "  - WhiteSur icons: not installed"
    fi

    if [ "$HAS_PTYXIS" = true ]; then
        echo "  - Terminal: Ptyxis found"
    elif [ "$HAS_GNOME_TERM" = true ]; then
        echo "  - Terminal: GNOME Terminal found"
    else
        echo "  - Terminal: neither Ptyxis nor GNOME Terminal found"
    fi

    if [ "$HAS_DCONF" = true ]; then
        echo "  - dconf: found"
    else
        echo "  - dconf: not found (needed to load extension presets)"
    fi
    echo ""
}

# Parse command line flags
if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            --all)
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                INSTALL_ICONS=true
                INSTALL_EXTENSIONS=true
                INSTALL_ROUNDED_BLUR=true
                INSTALL_TERMINAL=true
                INSTALL_SHELL=true
                INSTALL_CONFIGS=true
                shift
                ;;
            --theme)
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                shift
                ;;
            --icons)
                INSTALL_ICONS=true
                shift
                ;;
            --extensions)
                INSTALL_EXTENSIONS=true
                INSTALL_ROUNDED_BLUR=true
                shift
                ;;
            --rounded-blur|--blur)
                INSTALL_ROUNDED_BLUR=true
                shift
                ;;
            --terminal)
                INSTALL_TERMINAL=true
                shift
                ;;
            --shell)
                INSTALL_SHELL=true
                shift
                ;;
            --configs|--extension-configs|--blur-settings)
                INSTALL_CONFIGS=true
                INSTALL_TERMINAL=true
                shift
                ;;
            --check)
                print_dependency_status
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
else
    # Interactive mode
    print_dependency_status

    read -p "Install GTK and Libadwaita theme (with macOS-style window buttons)? [Y/n]: " ans_theme || true
    case "${ans_theme:-y}" in [yY]*) INSTALL_THEME=true; INSTALL_LIBADWAITA=true ;; esac

    read -p "Install WhiteSur icons? [y/N]: " ans_icons || true
    case "$ans_icons" in [yY]*) INSTALL_ICONS=true ;; esac

    if [ "$HAS_GNOME_EXT" = true ]; then
        read -p "Install GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)? [y/N]: " ans_ext || true
        case "$ans_ext" in
            [yY]*)
                INSTALL_EXTENSIONS=true
                INSTALL_ROUNDED_BLUR=true
                ;;
        esac
    else
        echo "Skipping extensions (gnome-extensions tool is not installed)."
    fi

    if [ "$INSTALL_ROUNDED_BLUR" != true ]; then
        read -p "Install gnome-rounded-blur (rounded dynamic corners for Blur my Shell)? [y/N]: " ans_blur || true
        case "$ans_blur" in [yY]*) INSTALL_ROUNDED_BLUR=true ;; esac
    fi

    read -p "Set terminal transparency to 75% (Ptyxis / GNOME Terminal)? [Y/n]: " ans_term || true
    case "${ans_term:-y}" in [yY]*) INSTALL_TERMINAL=true ;; esac

    read -p "Install shell config (.bashrc with Starship prompt)? [y/N]: " ans_shell || true
    case "$ans_shell" in [yY]*) INSTALL_SHELL=true ;; esac

    if [ "$HAS_DCONF" = true ]; then
        read -p "Apply recommended extension settings? [y/N]: " ans_configs || true
        case "$ans_configs" in [yY]*) INSTALL_CONFIGS=true ;; esac
    fi
fi

echo ""

# 1. Install GTK Theme & button layout
if [ "$INSTALL_THEME" = true ]; then
    echo "Installing GTK theme to $DEST_THEMES_DIR/WhiteSur-glassy..."
    mkdir -p "$DEST_THEMES_DIR"
    cp -rf "$THEME_DIR" "$DEST_THEMES_DIR/"

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-glassy" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:" 2>/dev/null || true
    fi
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-glassy'" 2>/dev/null || true
    fi
fi

# 2. Setup Libadwaita overrides
if [ "$INSTALL_LIBADWAITA" = true ]; then
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" install
fi

# 3. Install WhiteSur Icons
if [ "$INSTALL_ICONS" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/install-icons.sh" ]; then
        bash "$SCRIPT_DIR/scripts/install-icons.sh"
    fi
fi

# 4. Install GNOME Extensions
if [ "$INSTALL_EXTENSIONS" = true ]; then
    if [ "$HAS_GNOME_EXT" = true ]; then
        if [ -f "$SCRIPT_DIR/scripts/install-extensions.sh" ]; then
            bash "$SCRIPT_DIR/scripts/install-extensions.sh"
        fi
    else
        echo "Cannot install extensions: gnome-extensions CLI is missing."
    fi
fi

# 5. Install gnome-rounded-blur
if [ "$INSTALL_ROUNDED_BLUR" = true ] && [ "$INSTALL_EXTENSIONS" != true ]; then
    if [ -f "$SCRIPT_DIR/scripts/install-rounded-blur.sh" ]; then
        bash "$SCRIPT_DIR/scripts/install-rounded-blur.sh"
    fi
fi

# 6. Configure Terminal Transparency
if [ "$INSTALL_TERMINAL" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/setup-terminal.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-terminal.sh"
    fi
fi

# 7. Setup Shell Configuration
if [ "$INSTALL_SHELL" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/setup-shell.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-shell.sh"
    fi
fi

# 8. Apply Extension Configurations
if [ "$INSTALL_CONFIGS" = true ]; then
    echo "Applying extension settings..."
    if [ "$HAS_DCONF" = true ]; then
        if [ -f "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/blur-my-shell/ < "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf"
        fi
        if [ -f "$SCRIPT_DIR/configs/dash-to-dock-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$SCRIPT_DIR/configs/dash-to-dock-glassy.dconf"
        fi
        if [ -f "$SCRIPT_DIR/configs/logo-menu-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/Logo-menu/ < "$SCRIPT_DIR/configs/logo-menu-glassy.dconf"
        fi
        dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-glassy'" 2>/dev/null || true
        echo "Extension settings applied."
    fi
fi

echo ""
echo "Installation complete!"

if [ -t 0 ]; then
    read -p "Would you like to log out now to apply the changes? [y/N]: " ans_logout
    case "$ans_logout" in
        [yY]*)
            echo "Logging out..."
            if command -v gnome-session-quit >/dev/null 2>&1; then
                gnome-session-quit --logout --no-prompt
            elif [ -n "$XDG_SESSION_ID" ] && command -v loginctl >/dev/null 2>&1; then
                loginctl terminate-session "$XDG_SESSION_ID"
            fi
            ;;
        *)
            echo "You can log out later for all changes to take effect."
            ;;
    esac
else
    echo "Log out and back in for all changes to take effect."
fi
