#!/bin/bash
set -e

# Linux Dynamic Wallpapers installer for WhiteSur-Glassy
# Upstream repository: https://github.com/saint-13/Linux_Dynamic_Wallpapers
# Note: The upstream interactive installer (Interactive_Install.sh) is broken.
# This script executes the complete installation script (install.sh) which installs
# all dynamic wallpapers and GNOME background XML slideshow definitions.
# Total download size: ~1.7 GB (~2 GB uncompressed disk space).

REPO_URL="https://github.com/saint-13/Linux_Dynamic_Wallpapers.git"
DEST_WALLPAPERS="/usr/share/backgrounds/Dynamic_Wallpapers"
DEST_XML="/usr/share/gnome-background-properties"

FORCE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
    FORCE=true
fi

if [ "$FORCE" = false ] && [ -d "$DEST_WALLPAPERS" ]; then
    echo "Linux Dynamic Wallpapers is already installed at $DEST_WALLPAPERS."
    echo "To reinstall, run with --force."
    exit 0
fi

echo "========================================================"
echo "Installing Linux Dynamic Wallpapers for GNOME..."
echo "Repository: https://github.com/saint-13/Linux_Dynamic_Wallpapers"
echo "Package size: ~1.7 GB download (~2 GB disk space)"
echo "========================================================"

# Helper to execute commands with root privileges when needed
run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "Error: root privileges (sudo) required to install wallpapers to /usr/share" >&2
        exit 1
    fi
}

CLEANUP_DIRS=()
cleanup() {
    for d in "${CLEANUP_DIRS[@]}"; do
        [ -d "$d" ] && rm -rf "$d"
    done
}
trap cleanup EXIT

# If running as root in an environment without sudo (e.g. minimal containers),
# provide a sudo wrapper because upstream install.sh hardcodes 'sudo' calls.
if [ "$EUID" -eq 0 ] && ! command -v sudo >/dev/null 2>&1; then
    SHIM_DIR=$(mktemp -d)
    CLEANUP_DIRS+=("$SHIM_DIR")
    echo '#!/bin/sh' > "$SHIM_DIR/sudo"
    echo 'exec "$@"' >> "$SHIM_DIR/sudo"
    chmod +x "$SHIM_DIR/sudo"
    export PATH="$SHIM_DIR:$PATH"
fi

# Determine source directory: custom environment override, local clone, or git clone
SRC_DIR="${DYNAMIC_WALLPAPERS_SRC:-}"

if [ -n "$SRC_DIR" ] && [ -d "$SRC_DIR" ] && [ -f "$SRC_DIR/install.sh" ]; then
    echo "Using local Linux Dynamic Wallpapers directory: $SRC_DIR"
    (cd "$SRC_DIR" && bash ./install.sh)
elif [ -d "$HOME/Tweaks/Linux_Dynamic_Wallpapers" ] && [ -f "$HOME/Tweaks/Linux_Dynamic_Wallpapers/install.sh" ]; then
    echo "Using local clone in $HOME/Tweaks/Linux_Dynamic_Wallpapers..."
    (cd "$HOME/Tweaks/Linux_Dynamic_Wallpapers" && bash ./install.sh)
elif command -v git >/dev/null 2>&1; then
    TMP_CLONE_DIR=$(mktemp -d)
    CLEANUP_DIRS+=("$TMP_CLONE_DIR")
    echo "Cloning Linux Dynamic Wallpapers repository (~1.7 GB)..."
    git clone --depth=1 "$REPO_URL" "$TMP_CLONE_DIR"
    echo "Running upstream install script..."
    (cd "$TMP_CLONE_DIR" && bash ./install.sh)
else
    echo "Error: git is required to download Linux Dynamic Wallpapers." >&2
    echo "Please install git or clone $REPO_URL manually." >&2
    exit 1
fi

# Ensure all users can read the dynamic wallpapers and XML definitions
if [ -d "$DEST_WALLPAPERS" ]; then
    run_sudo chmod -R a+rX "$DEST_WALLPAPERS" 2>/dev/null || true
fi
if [ -d "$DEST_XML" ]; then
    run_sudo chmod a+r "$DEST_XML"/*.xml 2>/dev/null || true
fi

echo ""
echo "Linux Dynamic Wallpapers installed successfully!"
echo "Open GNOME Settings -> Background to choose a dynamic wallpaper."
