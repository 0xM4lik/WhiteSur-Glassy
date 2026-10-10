# YouTube Music Flatpak Glassy Tweak

This directory contains the automated patcher to give the **YouTube Music Flatpak** (`com.github.th_ch.youtube_music`) a frosted glass, translucent look matching GNOME and Blur my Shell.

---

## Technical Architecture

Electron applications do not inherit GTK theme transparency automatically because:
1. **Window Surface Compositor**: By default, `BrowserWindow` renders on an opaque RGB visual with `backgroundColor: "#000"`.
2. **Web DOM Styling**: YouTube Music's web client (`music.youtube.com`) renders solid black containers across `#layout`, `#nav-bar-background`, `#player-bar-background`, `#browse-page`, and `#guide-wrapper`.
3. **Platform Restrictions**: The upstream `th-ch/youtube-music` repository includes a built-in `transparent-player` plugin, but locks it to `Platform.Windows` due to its Windows-specific Mica/Acrylic implementation.

### How the Patch Works
- **Electron Alpha Visual**: Enables `transparent: true`, `backgroundColor: "#00000000"`, and `enable-transparent-visuals` in the main process.
- **Cross-Platform Plugin**: Unlocks the built-in `transparent-player` plugin for Linux (`Platform.Linux`) and sets the default opacity to 75%.
- **Translucent Styling**: Injects CSS overrides targeting all dark containers with `rgba(20, 20, 22, 0.75)` and `backdrop-filter: blur(20px)`, while leaving album art, track titles, lyrics, and controls 100% opaque and sharp.
- **Flatpak Non-Destructive Deployment**: Utilizes Flatpak's native `--app-path` parameter with a Btrfs CoW clone in `~/.local/share/youtube-music-glassy` (taking zero duplicate disk space), leaving system packages untouched.

---

## Usage

### Install
```bash
./patch-youtube-music.sh
```

### Rollback
```bash
./restore-youtube-music.sh
```
