#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_TRANSPARENT_DIR="$SCRIPT_DIR/theme/WhiteSur-Glassy-Transparent"
THEME_TINTED_DIR="$SCRIPT_DIR/theme/WhiteSur-Glassy-Tinted"
LIBADWAITA_DIR="$SCRIPT_DIR/theme/libadwaita"
DEST_THEMES_DIR="$HOME/.themes"
XDG_THEMES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"

THEME_VARIANT=""
ACTIVE_THEME_NAME=""
HAS_COMPONENT_FLAGS=false

INSTALL_THEME=false
INSTALL_LIBADWAITA=false
INSTALL_FLATPAK=false
INSTALL_ICONS=false
INSTALL_EXTENSIONS=false
INSTALL_TERMINAL=false
INSTALL_CONFIGS=false

check_tool() {
    command -v "$1" >/dev/null 2>&1
}

HAS_PYTHON=false
HAS_GNOME_EXT=false
HAS_ROUNDED_BLUR=false
HAS_DCONF=false
HAS_FLATPAK=false
HAS_ICONS=false
HAS_PTYXIS=false
HAS_GNOME_TERM=false

check_tool python3 && HAS_PYTHON=true
check_tool gnome-extensions && HAS_GNOME_EXT=true
check_tool dconf && HAS_DCONF=true
check_tool flatpak && HAS_FLATPAK=true

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

Theme Variant Options:
  --transparent    Select WhiteSur-Glassy-Transparent (100% fully transparent windows, sidebars, dialogs & popovers)
  --tinted         Select WhiteSur-Glassy-Tinted (75% translucent windows with dark glass tint)

Component Options:
  --all            Install everything (GTK/Libadwaita themes, window buttons, Flatpak overrides, terminal transparency, extensions & presets, icons)
  --theme          Install GTK 3/4 themes, Libadwaita overrides, Flatpak overrides, left-side window buttons, and terminal transparency
  --extensions     Install GNOME extensions (Blur my Shell, Dash to Dock, Logo Menu, User Themes), gnome-rounded-blur, and glassy presets
  --icons          Install WhiteSur icons
  --terminal       Configure terminal transparency to match selected theme (Ptyxis and GNOME Terminal)
  --flatpak        Configure Flatpak overrides (GTK 3/4 theme, Libadwaita, icons)
  --check          Check system dependencies
  --help, -h       Show this help message

Running without arguments starts interactive setup.
When running non-interactively with --all, --theme, or --terminal, you must specify --transparent or --tinted.
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

    if [ "$HAS_FLATPAK" = true ]; then
        echo "  - flatpak: found"
    else
        echo "  - flatpak: not found (Flatpak theme overrides will be skipped)"
    fi
    echo ""
}

prompt_theme_variant() {
    echo "Select a WhiteSur-Glassy theme variant:"
    echo "  1) WhiteSur-Glassy-Transparent (100% fully transparent — every window, sidebar, dialog & popover is 100% transparent)"
    echo "  2) WhiteSur-Glassy-Tinted      (75% translucent windows with dark glass tint)"
    read -p "Choose theme [1/2] (default: 1): " ans_variant || true
    case "${ans_variant:-1}" in
        2|[tT]inted*|[wW]hiteSur-[gG]lassy-[tT]inted)
            THEME_VARIANT="tinted"
            ACTIVE_THEME_NAME="WhiteSur-Glassy-Tinted"
            ;;
        1|[tT]ransparent*|[wW]hiteSur-[gG]lassy-[tT]ransparent|*)
            THEME_VARIANT="transparent"
            ACTIVE_THEME_NAME="WhiteSur-Glassy-Transparent"
            ;;
    esac
    echo "Selected theme: $ACTIVE_THEME_NAME"
    echo ""
}

run_interactive_component_prompts() {
    read -p "Install GTK & Libadwaita themes (with traffic lights, Flatpak, and terminal transparency)? [Y/n]: " ans_theme || true
    case "${ans_theme:-y}" in
        [yY]*)
            INSTALL_THEME=true
            INSTALL_LIBADWAITA=true
            INSTALL_FLATPAK=true
            INSTALL_TERMINAL=true
            ;;
    esac

    if [ "$HAS_GNOME_EXT" = true ]; then
        read -p "Install GNOME extensions (Blur my Shell, rounded blur, Dash to Dock, Logo Menu, presets)? [Y/n]: " ans_ext || true
        case "${ans_ext:-y}" in
            [yY]*)
                INSTALL_EXTENSIONS=true
                INSTALL_CONFIGS=true
                ;;
        esac
    else
        echo "Skipping extensions (gnome-extensions CLI tool is not installed)."
    fi

    read -p "Install WhiteSur icons? [y/N]: " ans_icons || true
    case "$ans_icons" in
        [yY]*)
            INSTALL_ICONS=true
            ;;
    esac
}

# Parse command line flags
if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            --transparent)
                THEME_VARIANT="transparent"
                ACTIVE_THEME_NAME="WhiteSur-Glassy-Transparent"
                shift
                ;;
            --tinted)
                THEME_VARIANT="tinted"
                ACTIVE_THEME_NAME="WhiteSur-Glassy-Tinted"
                shift
                ;;
            --all)
                HAS_COMPONENT_FLAGS=true
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                INSTALL_FLATPAK=true
                INSTALL_TERMINAL=true
                INSTALL_EXTENSIONS=true
                INSTALL_CONFIGS=true
                INSTALL_ICONS=true
                shift
                ;;
            --theme)
                HAS_COMPONENT_FLAGS=true
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                INSTALL_FLATPAK=true
                shift
                ;;
            --flatpak)
                HAS_COMPONENT_FLAGS=true
                INSTALL_FLATPAK=true
                shift
                ;;
            --icons)
                HAS_COMPONENT_FLAGS=true
                INSTALL_ICONS=true
                shift
                ;;
            --extensions)
                HAS_COMPONENT_FLAGS=true
                INSTALL_EXTENSIONS=true
                INSTALL_CONFIGS=true
                shift
                ;;
            --terminal)
                HAS_COMPONENT_FLAGS=true
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

    # If only --transparent or --tinted was passed without component flags:
    if [ "$HAS_COMPONENT_FLAGS" != true ]; then
        if [ -t 0 ]; then
            print_dependency_status
            echo "Selected theme: $ACTIVE_THEME_NAME"
            echo ""
            run_interactive_component_prompts
        else
            INSTALL_THEME=true
            INSTALL_LIBADWAITA=true
            INSTALL_FLATPAK=true
        fi
    fi

    # If theme/terminal flags were given without --transparent or --tinted:
    if [ -z "$THEME_VARIANT" ] && { [ "$INSTALL_THEME" = true ] || [ "$INSTALL_LIBADWAITA" = true ] || [ "$INSTALL_TERMINAL" = true ]; }; then
        if [ -t 0 ]; then
            prompt_theme_variant
        else
            echo "Error: Please specify a theme variant (--transparent or --tinted) when running non-interactively." >&2
            show_help >&2
            exit 1
        fi
    fi
else
    # Interactive mode
    print_dependency_status
    prompt_theme_variant
    run_interactive_component_prompts
fi

echo ""

# 1. Install GTK Themes (both Transparent & Tinted) & activate selected variant
if [ "$INSTALL_THEME" = true ]; then
    echo "Installing WhiteSur-Glassy-Transparent and WhiteSur-Glassy-Tinted to $DEST_THEMES_DIR and $XDG_THEMES_DIR..."
    mkdir -p "$DEST_THEMES_DIR" "$XDG_THEMES_DIR"

    # Clean up legacy single-theme folder if present
    rm -rf "$DEST_THEMES_DIR/WhiteSur-glassy" "$XDG_THEMES_DIR/WhiteSur-glassy"
    rm -rf "$DEST_THEMES_DIR/WhiteSur-Glassy-Transparent" "$XDG_THEMES_DIR/WhiteSur-Glassy-Transparent"
    rm -rf "$DEST_THEMES_DIR/WhiteSur-Glassy-Tinted" "$XDG_THEMES_DIR/WhiteSur-Glassy-Tinted"

    cp -rf "$THEME_TRANSPARENT_DIR" "$DEST_THEMES_DIR/"
    cp -rf "$THEME_TRANSPARENT_DIR" "$XDG_THEMES_DIR/"
    cp -rf "$THEME_TINTED_DIR" "$DEST_THEMES_DIR/"
    cp -rf "$THEME_TINTED_DIR" "$XDG_THEMES_DIR/"

    echo "Activating GTK & GNOME Shell theme: $ACTIVE_THEME_NAME..."
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "$ACTIVE_THEME_NAME" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.preferences button-layout "close,minimize,maximize:" 2>/dev/null || true
    fi
    if command -v dconf >/dev/null 2>&1; then
        dconf write /org/gnome/shell/extensions/user-theme/name "'$ACTIVE_THEME_NAME'" 2>/dev/null || true
    fi
fi

# 2. Setup Libadwaita overrides
if [ "$INSTALL_LIBADWAITA" = true ]; then
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" install "$THEME_VARIANT"
fi

# 3. Install WhiteSur Icons
if [ "$INSTALL_ICONS" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/install-icons.sh" ]; then
        bash "$SCRIPT_DIR/scripts/install-icons.sh"
    fi
fi

# 3b. Configure Flatpak overrides
if [ "$INSTALL_FLATPAK" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/setup-flatpak.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-flatpak.sh" install "$THEME_VARIANT"
    fi

    # If only --flatpak was specified, finish immediately without logout prompt
    if [ "$INSTALL_THEME" != true ] && [ "$INSTALL_LIBADWAITA" != true ] && [ "$INSTALL_ICONS" != true ] && [ "$INSTALL_EXTENSIONS" != true ] && [ "$INSTALL_TERMINAL" != true ] && [ "$INSTALL_CONFIGS" != true ]; then
        echo ""
        echo "Flatpak configuration complete! Restart your Flatpak apps to see changes."
        exit 0
    fi
fi

# 4. Install GNOME Extensions & apply presets
if [ "$INSTALL_EXTENSIONS" = true ]; then
    if [ "$HAS_GNOME_EXT" = true ]; then
        if [ -f "$SCRIPT_DIR/scripts/install-extensions.sh" ]; then
            WHITESUR_THEME_NAME="${ACTIVE_THEME_NAME:-WhiteSur-Glassy-Transparent}" bash "$SCRIPT_DIR/scripts/install-extensions.sh"
        fi
    else
        echo "Cannot install extensions: gnome-extensions CLI is missing."
    fi
fi

# 5. Configure Terminal Transparency
if [ "$INSTALL_TERMINAL" = true ]; then
    if [ -f "$SCRIPT_DIR/scripts/setup-terminal.sh" ]; then
        bash "$SCRIPT_DIR/scripts/setup-terminal.sh" "${THEME_VARIANT:-transparent}"
    fi
fi

# 6. Apply Extension Configurations
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
        dconf write /org/gnome/shell/extensions/user-theme/name "'${ACTIVE_THEME_NAME:-WhiteSur-Glassy-Transparent}'" 2>/dev/null || true
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
