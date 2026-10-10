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
INSTALL_TERMINAL=false
INSTALL_SHELL=false
INSTALL_CONFIGS=false

# ==============================================================================
# Dependency Checking Helpers
# ==============================================================================
check_tool() {
    command -v "$1" >/dev/null 2>&1
}

HAS_PYTHON=false
HAS_GNOME_EXT=false
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

if check_tool gsettings; then
    gsettings list-schemas | grep -q "org.gnome.Ptyxis" && HAS_PTYXIS=true
    gsettings list-schemas | grep -q "org.gnome.Terminal.ProfilesList" && HAS_GNOME_TERM=true
fi

show_help() {
    cat << HELP_EOF
Usage: ./install.sh [OPTIONS]

Options:
  --all            Install all components (Theme, Window Controls, Icons, Extensions, Terminal, Shell, Configs)
  --theme          Install GTK 2/3/4 theme, Libadwaita glassy overrides, and Apple window traffic lights
  --icons          Install WhiteSur Apple-style icon theme (authentic macOS icons)
  --extensions     Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)
  --terminal       Configure 75% terminal transparency for Ptyxis and GNOME Terminal
  --shell          Install clean glassy shell configuration (.bashrc with Starship prompt)
  --configs        Apply recommended extension configurations (Dash to Dock, Blur my Shell, Logo Menu) & Terminal
  --blur-settings  Alias for --configs
  --check          Only check dependencies and environment status
  --help, -h       Show this help message

Running without arguments starts an interactive setup.
HELP_EOF
}

print_dependency_status() {
    echo "============================================="
    echo "       System & Dependency Status            "
    echo "============================================="
    if [ "$HAS_PYTHON" = true ]; then
        echo "  [✓] Python 3: $(python3 --version 2>&1)"
    else
        echo "  [!] Python 3: Not found"
    fi

    if [ "$HAS_GNOME_EXT" = true ]; then
        echo "  [✓] gnome-extensions CLI: Available"
    else
        echo "  [✗] gnome-extensions CLI: NOT FOUND"
        echo "      (Required to automatically install GNOME extensions)"
        echo "      Fedora: sudo dnf install gnome-shell"
        echo "      Ubuntu: sudo apt install gnome-shell gnome-shell-extension-prefs"
        echo "      Arch:   sudo pacman -S gnome-shell"
    fi

    if [ "$HAS_ICONS" = true ]; then
        echo "  [✓] WhiteSur Icon Theme: Installed"
    else
        echo "  [!] WhiteSur Icon Theme: Not installed"
        echo "      (Install via: ./install.sh --icons)"
    fi

    if [ "$HAS_PTYXIS" = true ]; then
        echo "  [✓] Ptyxis Terminal: Supported (Fedora default)"
    elif [ "$HAS_GNOME_TERM" = true ]; then
        echo "  [✓] GNOME Terminal: Supported"
    else
        echo "  [!] Terminal: Standard terminal profiles not detected"
    fi

    if [ "$HAS_DCONF" = true ]; then
        echo "  [✓] dconf: Available"
    else
        echo "  [!] dconf: Not found (required to auto-load extension presets)"
    fi
    echo "============================================="
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
    echo ""

    read -p "Install WhiteSur-glassy GTK & Libadwaita theme (with Apple traffic lights)? [Y/n]: " ans_theme
    case "${ans_theme:-y}" in [yY]*) INSTALL_THEME=true; INSTALL_LIBADWAITA=true ;; esac

    read -p "Install WhiteSur Apple-style icon theme? [y/N]: " ans_icons
    case "$ans_icons" in [yY]*) INSTALL_ICONS=true ;; esac

    if [ "$HAS_GNOME_EXT" = true ]; then
        read -p "Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)? [y/N]: " ans_ext
        case "$ans_ext" in [yY]*) INSTALL_EXTENSIONS=true ;; esac
    else
        echo "[!] Skipping GNOME extensions prompt: gnome-extensions CLI is not installed."
    fi

    read -p "Configure 75% terminal transparency (Ptyxis & GNOME Terminal)? [Y/n]: " ans_term
    case "${ans_term:-y}" in [yY]*) INSTALL_TERMINAL=true ;; esac

    read -p "Install sleek glassy shell configuration (.bashrc with Starship prompt)? [y/N]: " ans_shell
    case "$ans_shell" in [yY]*) INSTALL_SHELL=true ;; esac

    if [ "$HAS_DCONF" = true ]; then
        read -p "Apply recommended extension configurations (Dash to Dock, Blur my Shell, Logo Menu)? [y/N]: " ans_configs
        case "$ans_configs" in [yY]*) INSTALL_CONFIGS=true ;; esac
    fi
fi

echo ""
echo "Starting installation..."

# 1. Install GTK Theme & Configure Apple Window Traffic Lights
if [ "$INSTALL_THEME" = true ]; then
    echo "-> Installing GTK Theme to $DEST_THEMES_DIR/WhiteSur-glassy..."
    mkdir -p "$DEST_THEMES_DIR"
    cp -rf "$THEME_DIR" "$DEST_THEMES_DIR/"

    if command -v gsettings >/dev/null 2>&1; then
        echo "-> Setting GTK theme to WhiteSur-glassy..."
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-glassy" 2>/dev/null || true
        echo "-> Configuring Apple window traffic lights layout (left-aligned)..."
        gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:" 2>/dev/null || true
    fi
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-glassy'" 2>/dev/null || true
    fi
    echo "[✓] GTK theme & Apple traffic lights configured."
fi

# 2. Setup Libadwaita overrides
if [ "$INSTALL_LIBADWAITA" = true ]; then
    echo "-> Setting up Libadwaita overrides in $USER_CONFIG_DIR..."
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" install
    echo "[✓] Libadwaita glassy theme installed."
fi

# 3. Install WhiteSur Icons
if [ "$INSTALL_ICONS" = true ]; then
    echo "-> Installing WhiteSur icon theme..."
    if [ -f "$SCRIPT_DIR/scripts/install-icons.sh" ]; then
        bash "$SCRIPT_DIR/scripts/install-icons.sh"
    fi
fi

# 4. Install GNOME Extensions
if [ "$INSTALL_EXTENSIONS" = true ]; then
    if [ "$HAS_GNOME_EXT" = true ]; then
        echo "-> Installing recommended GNOME extensions..."
        if [ -f "$SCRIPT_DIR/scripts/install-extensions.sh" ]; then
            bash "$SCRIPT_DIR/scripts/install-extensions.sh"
        fi
    else
        echo "[!] Cannot install GNOME extensions: 'gnome-extensions' CLI tool is missing."
        echo "    Install with: sudo dnf install gnome-shell (Fedora) or sudo apt install gnome-shell (Ubuntu)"
    fi
fi

# 5. Configure Terminal Transparency (Ptyxis & GNOME Terminal)
if [ "$INSTALL_TERMINAL" = true ]; then
    echo "-> Setting up terminal transparency..."
    if [ -f "$SCRIPT_DIR/scripts/setup-terminal.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-terminal.sh"
    fi
fi

# 6. Setup Shell Configuration (.bashrc)
if [ "$INSTALL_SHELL" = true ]; then
    echo "-> Setting up glassy shell configuration..."
    if [ -f "$SCRIPT_DIR/scripts/setup-shell.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-shell.sh"
    fi
fi

# 7. Extension Configurations (Dash to Dock, Blur my Shell, Logo Menu)
if [ "$INSTALL_CONFIGS" = true ]; then
    echo "-> Applying extension configurations..."
    if [ "$HAS_DCONF" = true ]; then
        if [ -f "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/blur-my-shell/ < "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf"
            echo "  [✓] Blur my Shell presets applied."
        fi
        if [ -f "$SCRIPT_DIR/configs/dash-to-dock-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$SCRIPT_DIR/configs/dash-to-dock-glassy.dconf"
            echo "  [✓] Dash to Dock presets applied."
        fi
        if [ -f "$SCRIPT_DIR/configs/logo-menu-glassy.dconf" ]; then
            dconf load /org/gnome/shell/extensions/Logo-menu/ < "$SCRIPT_DIR/configs/logo-menu-glassy.dconf"
            echo "  [✓] Logo Menu presets applied."
        fi
        dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-glassy'" 2>/dev/null || true
        echo "[✓] All extension configurations applied."
    else
        echo "[!] dconf command not available or preset file missing. Skipping."
    fi
fi

echo ""
echo "============================================="
echo "   WhiteSur-Glassy installation complete!    "
echo "============================================="
