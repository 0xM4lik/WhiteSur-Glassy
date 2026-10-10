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

# ==============================================================================
# Dependency Checking Helpers
# ==============================================================================
check_tool() {
    command -v "$1" >/dev/null 2>&1
}

HAS_PYTHON=false
HAS_GNOME_EXT=false
HAS_FLATPAK=false
HAS_YTM=false
HAS_DCONF=false

check_tool python3 && HAS_PYTHON=true
check_tool gnome-extensions && HAS_GNOME_EXT=true
check_tool flatpak && HAS_FLATPAK=true
check_tool dconf && HAS_DCONF=true

if [ "$HAS_FLATPAK" = true ]; then
    if flatpak list 2>/dev/null | grep -q "com.github.th_ch.youtube_music" || \
       [ -d "/var/lib/flatpak/app/com.github.th_ch.youtube_music" ] || \
       [ -d "$HOME/.local/share/flatpak/app/com.github.th_ch.youtube_music" ]; then
        HAS_YTM=true
    fi
fi

show_help() {
    cat << HELP_EOF
Usage: ./install.sh [OPTIONS]

Options:
  --all            Install all components (Theme, Libadwaita, Extensions, YouTube Music, Blur settings)
  --theme          Install GTK 2/3/4 theme and Libadwaita glassy overrides
  --extensions     Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)
  --youtube-music  Patch YouTube Music Flatpak for glassy transparency
  --blur-settings  Apply recommended Blur my Shell dconf presets
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
        echo "  [✗] Python 3: NOT FOUND (required for theme scripts & patchers)"
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

    if [ "$HAS_FLATPAK" = true ]; then
        echo "  [✓] Flatpak: $(flatpak --version 2>&1)"
        if [ "$HAS_YTM" = true ]; then
            echo "  [✓] YouTube Music Flatpak: Installed"
        else
            echo "  [!] YouTube Music Flatpak: Not installed"
            echo "      (Install via: flatpak install flathub com.github.th_ch.youtube_music)"
        fi
    else
        echo "  [✗] Flatpak: NOT FOUND"
        echo "      (Required to run and patch the YouTube Music Flatpak)"
    fi

    if [ "$HAS_DCONF" = true ]; then
        echo "  [✓] dconf: Available"
    else
        echo "  [!] dconf: Not found (required to auto-load Blur my Shell presets)"
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

    read -p "Install WhiteSur-glassy GTK & Libadwaita theme? [Y/n]: " ans_theme
    case "${ans_theme:-y}" in [yY]*) INSTALL_THEME=true; INSTALL_LIBADWAITA=true ;; esac

    if [ "$HAS_GNOME_EXT" = true ]; then
        read -p "Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)? [y/N]: " ans_ext
        case "$ans_ext" in [yY]*) INSTALL_EXTENSIONS=true ;; esac
    else
        echo "[!] Skipping GNOME extensions prompt: gnome-extensions CLI is not installed."
    fi

    if [ "$HAS_FLATPAK" = true ]; then
        if [ "$HAS_YTM" = true ]; then
            read -p "Patch YouTube Music Flatpak for transparency? [y/N]: " ans_ytm
            case "$ans_ytm" in [yY]*) INSTALL_YTM=true ;; esac
        else
            read -p "YouTube Music Flatpak is not installed. Would you like to install it from Flathub now? [y/N]: " ans_install_ytm
            case "$ans_install_ytm" in
                [yY]*)
                    echo "-> Installing com.github.th_ch.youtube_music from Flathub..."
                    flatpak install -y flathub com.github.th_ch.youtube_music
                    HAS_YTM=true
                    INSTALL_YTM=true
                    ;;
                *)
                    echo "[!] Skipping YouTube Music patch."
                    ;;
            esac
        fi
    else
        echo "[!] Skipping YouTube Music patch: Flatpak is not installed."
    fi

    if [ "$HAS_DCONF" = true ]; then
        read -p "Apply recommended Blur my Shell presets? [y/N]: " ans_blur
        case "$ans_blur" in [yY]*) INSTALL_BLUR=true ;; esac
    fi
fi

echo ""
echo "Starting installation..."

# 1. Install GTK Theme
if [ "$INSTALL_THEME" = true ]; then
    echo "-> Installing GTK Theme to $DEST_THEMES_DIR/WhiteSur-glassy..."
    mkdir -p "$DEST_THEMES_DIR"
    cp -rf "$THEME_DIR" "$DEST_THEMES_DIR/"

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

# 4. Patch YouTube Music Flatpak
if [ "$INSTALL_YTM" = true ]; then
    if [ "$HAS_FLATPAK" = false ]; then
        echo "[!] Cannot patch YouTube Music: 'flatpak' command not found."
    elif [ "$HAS_YTM" = false ]; then
        echo "[!] YouTube Music Flatpak (com.github.th_ch.youtube_music) is not installed."
        echo "    Install it via: flatpak install flathub com.github.th_ch.youtube_music"
        echo "    Then rerun: ./install.sh --youtube-music"
    else
        echo "-> Patching YouTube Music Flatpak..."
        bash "$SCRIPT_DIR/apps/youtube-music/patch-youtube-music.sh"
        echo "[✓] YouTube Music Flatpak patched successfully."
    fi
fi

# 5. Blur my Shell configuration
if [ "$INSTALL_BLUR" = true ]; then
    if [ "$HAS_DCONF" = true ] && [ -f "$SCRIPT_DIR/configs/blur-my-shell-glassy.dconf" ]; then
        echo "-> Applying Blur my Shell configuration..."
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
