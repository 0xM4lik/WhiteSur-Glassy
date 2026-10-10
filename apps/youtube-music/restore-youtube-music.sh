#!/bin/bash
set -e

echo "=== Restoring YouTube Music Flatpak to Original State ==="
FLATPAK_ID="com.github.th_ch.youtube_music"

flatpak kill "$FLATPAK_ID" 2>/dev/null || true
pkill -f "youtube-music" 2>/dev/null || true
sleep 1

rm -f "$HOME/.local/share/applications/com.github.th_ch.youtube_music.desktop"
rm -f "$HOME/.local/bin/youtube-music"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

BACKUP_CFG="$HOME/.local/share/youtube-music-glassy/backup/config.json.bak"
TARGET_CFG="$HOME/.var/app/$FLATPAK_ID/config/YouTube Music/config.json"
if [ -f "$BACKUP_CFG" ]; then
    cp -f "$BACKUP_CFG" "$TARGET_CFG"
    echo "Restored original config.json."
fi

rm -rf "$HOME/.local/share/youtube-music-glassy"
echo "YouTube Music successfully restored to default system Flatpak."
