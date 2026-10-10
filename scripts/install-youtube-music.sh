#!/bin/bash
set -e

echo "=== YouTube Music Flatpak Downloader & Installer ==="

if ! command -v flatpak >/dev/null 2>&1; then
    echo "Error: 'flatpak' is not installed on this system."
    echo "Please install flatpak first: https://flatpak.org/setup/"
    exit 1
fi

echo "-> Fetching latest YouTube Music release information from GitHub..."

DOWNLOAD_URL=""
if command -v python3 >/dev/null 2>&1; then
    DOWNLOAD_URL=$(python3 -c "
import urllib.request, json
req = urllib.request.Request('https://api.github.com/repos/th-ch/youtube-music/releases/latest', headers={'User-Agent': 'WhiteSur-Glassy-Installer'})
try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode())
        for asset in data.get('assets', []):
            name = asset.get('name', '')
            if name.endswith('.flatpak') and ('x86_64' in name or 'amd64' in name):
                print(asset['browser_download_url'])
                break
except Exception:
    pass
" 2>/dev/null || true)
fi

# Fallback: determine download URL from GitHub redirect if api fails or is rate-limited
if [ -z "$DOWNLOAD_URL" ] && command -v curl >/dev/null 2>&1; then
    LATEST_TAG=$(curl -sL -o /dev/null -w "%{url_effective}" https://github.com/pear-devs/pear-desktop/releases/latest 2>/dev/null | grep -o "[^/]*$" || true)
    if [ -n "$LATEST_TAG" ]; then
        VERSION="${LATEST_TAG#v}"
        DOWNLOAD_URL="https://github.com/pear-devs/pear-desktop/releases/download/${LATEST_TAG}/YouTube-Music-${VERSION}-x86_64.flatpak"
    fi
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Unable to automatically determine the latest download URL from GitHub."
    echo "Please download the .flatpak manually from:"
    echo "  https://github.com/pear-devs/pear-desktop/releases"
    echo "And install it using:"
    echo "  flatpak install YouTube-Music-*-x86_64.flatpak"
    exit 1
fi

TMP_DIR=$(mktemp -d)
FLATPAK_FILE="$TMP_DIR/YouTube-Music.flatpak"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

echo "-> Downloading: $DOWNLOAD_URL"
if command -v curl >/dev/null 2>&1; then
    curl -fL --progress-bar "$DOWNLOAD_URL" -o "$FLATPAK_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress "$DOWNLOAD_URL" -O "$FLATPAK_FILE"
elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import urllib.request, sys
urllib.request.urlretrieve(sys.argv[1], sys.argv[2])
" "$DOWNLOAD_URL" "$FLATPAK_FILE"
else
    echo "Error: Neither curl, wget, nor python3 is available to download the file."
    exit 1
fi

echo "-> Installing YouTube Music Flatpak (user installation)..."
flatpak install --user -y "$FLATPAK_FILE"

echo "[✓] YouTube Music Flatpak installed successfully."
