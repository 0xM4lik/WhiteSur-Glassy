#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/theme/WhiteSur-glassy"
LIBADWAITA_DIR="$SCRIPT_DIR/theme/libadwaita"
DEST_THEMES_DIR="${XDG_DATA_HOME:-$HOME/.themes}"
USER_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0"

INSTALL_THEME=false
INSTALL_LIBADWAITA=false
INSTALL_EXTENSIONS=false
INSTALL_YTM=false
INSTALL_BLUR=false

show_help() {
    cat << HELP_EOF
Usage: ./install.sh [OPTIONS]

Options:
  --all            Install all components (Theme, Libadwaita, Extensions, YouTube Music, Blur settings)
  --theme          Install GTK 2/3/4 theme and Libadwaita glassy overrides
  --extensions     Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)
  --youtube-music  Patch YouTube Music Flatpak for glassy transparency
  --blur-settings  Apply recommended Blur my Shell dconf presets
  --help, -h       Show this help message

Running without arguments starts an interactive setup.
HELP_EOF
}

# Parse command line flags
if [ $# -gt 0 ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            --all)
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                INSTALL_EXTENSIONS=true
                INSTALL_YTM=true
                INSTALL_BLUR=true
                shift
                ;;
            --theme)
                INSTALL_THEME=true
                INSTALL_LIBADWAITA=true
                shift
                ;;
            --extensions)
                INSTALL_EXTENSIONS=true
                shift
                ;;
            --youtube-music)
                INSTALL_YTM=true
                shift
                ;;
            --blur-settings)
                INSTALL_BLUR=true
                shift
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
    echo "============================================="
    echo "     WhiteSur-Glassy Theme Installer         "
    echo "============================================="
    echo ""
    read -p "Install WhiteSur-glassy GTK & Libadwaita theme? [Y/n]: " ans_theme
    case "${ans_theme:-y}" in [yY]*) INSTALL_THEME=true; INSTALL_LIBADWAITA=true ;; esac

    read -p "Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)? [y/N]: " ans_ext
    case "$ans_ext" in [yY]*) INSTALL_EXTENSIONS=true ;; esac

    read -p "Patch YouTube Music Flatpak for transparency? [y/N]: " ans_ytm
    case "$ans_ytm" in [yY]*) INSTALL_YTM=true ;; esac

    read -p "Apply recommended Blur my Shell presets? [y/N]: " ans_blur
    case "$ans_blur" in [yY]*) INSTALL_BLUR=true ;; esac
fi

echo ""
echo "Starting installation..."

# 1. Install GTK Theme
if [ "$INSTALL_THEME" = true ]; then
    echo "-> Installing GTK Theme to $DEST_THEMES_DIR/WhiteSur-glassy..."
    mkdir -p "$DEST_THEMES_DIR"
    cp -rf "$THEME_DIR" "$DEST_THEMES_DIR/"

    # Set theme via gsettings if available
    if command -v gsettings >/dev/null 2>&1; then
        echo "-> Setting GTK theme to WhiteSur-glassy..."
        gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-glassy" 2>/dev/null || true
    fi
    echo "[✓] GTK theme installed."
fi

# 2. Setup Libadwaita overrides
if [ "$INSTALL_LIBADWAITA" = true ]; then
    echo "-> Setting up Libadwaita overrides in $USER_CONFIG_DIR..."
    bash "$LIBADWAITA_DIR/setup-libadwaita.sh" install
    echo "[✓] Libadwaita glassy theme installed."
fi

# 3. Install GNOME Extensions
if [ "$INSTALL_EXTENSIONS" = true ]; then
    echo "-> Installing recommended GNOME extensions..."
    if [ -f "$SCRIPT_DIR/scripts/install-extensions.sh" ]; then
        bash "$SCRIPT_DIR/scripts/install-extensions.sh"
    fi
fi

# 4. Patch YouTube Music Flatpak
if [ "$INSTALL_YTM" = true ]; then
    echo "-> Checking YouTube Music Flatpak..."
    if command -v flatpak >/dev/null 2>&1 && flatpak list | grep -q "com.github.th_ch.youtube_music"; then
        bash "$SCRIPT_DIR/apps/youtube-music/patch-youtube-music.sh"
        echo "[✓] YouTube Music Flatpak patched successfully."
    else
        echo "[!] YouTube Music Flatpak is not installed. Skipping patch."
    fi
fi

# 5. Blur my Shell configuration
if [ "$INSTALL_BLUR" = true ]; then
    echo "-> Applying Blur my Shell configuration..."
    if command -v dconf >/dev/null 2>&1 && [ -f "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf" ]; then
        dconf load /org/gnome/shell/extensions/blur-my-shell/ < "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf"
        echo "[✓] Blur my Shell presets applied."
    else
        echo "[!] dconf command not available or preset file missing. Skipping."
    fi
fi

echo ""
echo "============================================="
echo "   WhiteSur-Glassy installation complete!    "
echo "============================================="
