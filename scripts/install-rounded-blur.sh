#!/bin/bash
set -e

# Helper script to automatically install gnome-rounded-blur for Blur my Shell.
# Upstream guide: https://github.com/aunetx/blur-my-shell/blob/master/scripts/GUIDE.md
# Upstream library: https://github.com/kancko/gnome-rounded-blur

ROUNDED_BLUR_SCRIPT_URL="https://raw.githubusercontent.com/aunetx/blur-my-shell/master/scripts/rounded_blur_build.sh"

run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

is_rounded_blur_installed() {
    # 1. Test GObject Introspection typelib
    if python3 -c "import gi; gi.require_version('Blur', '1.0'); from gi.repository import Blur" >/dev/null 2>&1; then
        return 0
    fi

    # 2. Check system package managers
    if command -v rpm >/dev/null 2>&1 && rpm -q --quiet gnome-rounded-blur >/dev/null 2>&1; then
        return 0
    fi
    if command -v pacman >/dev/null 2>&1 && pacman -Q gnome-rounded-blur >/dev/null 2>&1; then
        return 0
    fi
    if command -v dpkg >/dev/null 2>&1 && dpkg -s gnome-rounded-blur >/dev/null 2>&1; then
        return 0
    fi

    # 3. Check file system paths
    for dir in /usr/lib64 /usr/lib /usr/lib/*-linux-gnu /usr/local/lib64 /usr/local/lib; do
        if [ -f "$dir/girepository-1.0/Blur-1.0.typelib" ] && { [ -f "$dir/libblur-effect-1.0.so" ] || [ -f "$dir/libblur-effect-1.0.so.1" ]; }; then
            return 0
        fi
    done

    return 1
}

FORCE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
    FORCE=true
fi

if [ "$FORCE" = false ] && is_rounded_blur_installed; then
    echo "gnome-rounded-blur is already installed."
    exit 0
fi

echo "========================================================"
echo "Installing gnome-rounded-blur for Blur my Shell..."
echo "Documentation: https://github.com/aunetx/blur-my-shell/blob/master/scripts/GUIDE.md"
echo "========================================================"

OS_ID=""
OS_ID_LIKE=""
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-}"
    OS_ID_LIKE="${ID_LIKE:-}"
fi

is_os_family() {
    local target="$1"
    for id in $OS_ID $OS_ID_LIKE; do
        if [ "$id" = "$target" ]; then
            return 0
        fi
    done
    return 1
}

get_gnome_version() {
    if command -v gnome-shell >/dev/null 2>&1; then
        gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -n 1 || echo "47"
    else
        echo "47"
    fi
}

# 1. Fedora / RHEL / Atomic
if is_os_family "fedora" || is_os_family "rhel"; then
    if command -v rpm-ostree >/dev/null 2>&1 && { [ -d /run/ostree-booted ] || [ -f /run/ostree-booted ]; }; then
        echo "Detected rpm-ostree system. Installing gnome-rounded-blur..."
        rpm-ostree install gnome-rounded-blur || {
            echo "Failed to install via rpm-ostree directly. Trying Copr repo..."
            run_sudo dnf copr enable -y ublue-os/packages 2>/dev/null || true
            rpm-ostree install gnome-rounded-blur
        }
    elif command -v dnf >/dev/null 2>&1; then
        echo "Installing gnome-rounded-blur on Fedora via Copr (ublue-os/packages)..."
        INSTALLED=false
        if run_sudo dnf copr enable -y ublue-os/packages; then
            # Disable repository globally to prevent unintentional package overrides
            run_sudo dnf config-manager disable copr:copr.fedorainfracloud.org:ublue-os:packages 2>/dev/null || \
            run_sudo dnf config-manager setopt copr:copr.fedorainfracloud.org:ublue-os:packages.enabled=0 2>/dev/null || \
            run_sudo dnf config-manager --set-disabled copr:copr.fedorainfracloud.org:ublue-os:packages 2>/dev/null || true

            if run_sudo dnf -y --enablerepo copr:copr.fedorainfracloud.org:ublue-os:packages install gnome-rounded-blur; then
                INSTALLED=true
            fi
        fi

        if [ "$INSTALLED" = false ]; then
            echo "Copr installation did not succeed. Falling back to build helper script..."
            GNOME_VER=$(get_gnome_version)
            SCRIPT_ARGS="-i -f"
            if [ "$GNOME_VER" -ge 51 ]; then
                SCRIPT_ARGS="-i -f -e"
            fi
            curl -fsSL "$ROUNDED_BLUR_SCRIPT_URL" | bash -s -- $SCRIPT_ARGS
        fi
    fi

# 2. Arch Linux / Manjaro / EndeavourOS
elif is_os_family "arch"; then
    echo "Installing gnome-rounded-blur on Arch Linux..."
    if command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm gnome-rounded-blur
    elif command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm gnome-rounded-blur
    elif command -v pamac >/dev/null 2>&1; then
        pamac build --no-confirm gnome-rounded-blur
    elif command -v pikaur >/dev/null 2>&1; then
        pikaur -S --noconfirm gnome-rounded-blur
    elif command -v makepkg >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        echo "Building gnome-rounded-blur from AUR using makepkg..."
        TMP_DIR=$(mktemp -d)
        cleanup_aur() {
            rm -rf "$TMP_DIR"
        }
        trap cleanup_aur EXIT
        git clone --depth=1 https://aur.archlinux.org/gnome-rounded-blur.git "$TMP_DIR/gnome-rounded-blur"
        (cd "$TMP_DIR/gnome-rounded-blur" && makepkg -si --noconfirm)
        trap - EXIT
        rm -rf "$TMP_DIR"
    else
        echo "No AUR helper or makepkg found. Please install gnome-rounded-blur from the AUR manually:"
        echo "https://aur.archlinux.org/packages/gnome-rounded-blur"
        exit 1
    fi

# 3. Debian / Ubuntu / openSUSE and generic distributions
else
    echo "Installing gnome-rounded-blur using the Blur my Shell helper script..."
    GNOME_VER=$(get_gnome_version)
    SCRIPT_ARGS="-i"
    if [ "$GNOME_VER" -ge 51 ]; then
        SCRIPT_ARGS="-i -e"
    fi
    curl -fsSL "$ROUNDED_BLUR_SCRIPT_URL" | bash -s -- $SCRIPT_ARGS
fi

# Verification
if is_rounded_blur_installed; then
    echo ""
    echo "✓ gnome-rounded-blur installed successfully!"
    echo "Notice: Log out and log back into your GNOME session for dynamic rounded corners to take effect."
else
    echo ""
    echo "Warning: Could not verify gnome-rounded-blur installation."
    echo "Please refer to the documentation for manual installation:"
    echo "https://github.com/aunetx/blur-my-shell/blob/master/scripts/GUIDE.md"
    exit 1
fi
