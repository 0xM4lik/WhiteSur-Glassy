<div align="center">

# WhiteSur-Glassy

**A curated frosted-glass desktop theme suite for GNOME & Blur my Shell.**

Translucent GTK 3, GTK 4, Libadwaita, and Flatpak application styling with sharp, 100% readable text and controls.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GNOME](https://img.shields.io/badge/GNOME-45%20|%2046%20|%2047%20|%2050+-3584e4.svg?logo=gnome)](https://www.gnome.org/)
[![Libadwaita](https://img.shields.io/badge/Libadwaita-Supported-brightgreen.svg)](https://gitlab.gnome.org/GNOME/libadwaita)
[![Flatpak](https://img.shields.io/badge/Flatpak-Transparent%20YTM-blueviolet.svg?logo=flatpak)](https://flatpak.org/)

</div>

---

## Overview

### The Problem
When using the [Blur my Shell](https://github.com/aunetx/blur-my-shell) extension on GNOME, window transparency is often frustrating:
- **Global window opacity hacks** make everything transparent — including text, buttons, and icons — making applications difficult to read.
- **Stock GTK and Libadwaita applications** (like Files/Nautilus, Calculator, and Software) hardcode multiple solid background layers, rendering as flat opaque grey boxes even when whitelisted.
- **Electron applications** (such as the YouTube Music Flatpak) initialize with opaque RGB visuals and solid black DOM containers, completely obscuring the blurred wallpaper behind them.

### The Solution: WhiteSur-Glassy
**WhiteSur-Glassy** transforms your desktop into an authentic frosted-glass interface:
1. **~75% Translucent Background Surfaces**: Window backdrops, sidebars, and navigation bars allow desktop wallpaper blur to shine through.
2. **100% Opaque & Crisp Foregrounds**: Text, icons, album covers, buttons, and inputs remain sharp, high-contrast, and fully readable.
3. **No Double-Layering**: Deep container hierarchies in Nautilus and Libadwaita are stripped of opaque background overrides.
4. **Third-Party App Parity**: Provides visual hooks and native transparency patches for Electron Flatpaks like **YouTube Music**.
5. **Automated GNOME Extensions**: Installs and activates Dash to Dock, Blur my Shell, Logo Menu, and User Themes automatically.

---

## Visual & Opacity Matrix

| Application / Surface | Rendered Opacity | Background Style | Text & Controls |
| :--- | :---: | :--- | :---: |
| **Nautilus (Files) Grid & Lists** | **75%** (`rgba(28, 28, 30, 0.75)`) | Frosted glass with desktop blur | 100% Opaque |
| **Nautilus Sidebar** | **70%** (`rgba(22, 22, 24, 0.70)`) | Deep glass contrast | 100% Opaque |
| **GNOME Calculator** | **75%** (`rgba(28, 28, 30, 0.75)`) | Translucent canvas + frosted display card | 100% Opaque |
| **GNOME Software** | **75%** (`rgba(28, 28, 30, 0.75)`) | Glass backdrop behind category tiles | 100% Opaque |
| **YouTube Music (Flatpak)** | **75%** (`rgba(20, 20, 22, 0.75)`) | Alpha visual with 20px frosted backdrop | 100% Opaque |
| **Window Traffic Lights** | — | Clean macOS circular dots (zero border) | 100% Opaque |

---

## Recommended GNOME Extensions

WhiteSur-Glassy includes an automated extension installer (`./install.sh --extensions`) that queries [extensions.gnome.org](https://extensions.gnome.org), downloads the version matching your GNOME Shell release, compiles extension schemas, and automatically activates them by default in GSettings & dconf (no manual GUI toggling required):

| Extension | UUID | Purpose |
| :--- | :--- | :--- |
| **[User Themes](https://extensions.gnome.org/extension/19/user-themes/)** | `user-theme@gnome-shell-extensions.gcampax.github.com` | Enables loading custom shell themes from `~/.themes`. |
| **[Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)** | `blur-my-shell@aunetx` | Blurs wallpapers behind windows, panel, and dock. |
| **[Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)** | `dash-to-dock@micxgx.gmail.com` | Turns the dash into a customizable macOS-style glass dock. |
| **[Logo Menu](https://extensions.gnome.org/extension/4451/logo-menu/)** | `logomenu@aryan_k` | Adds an Apple or distro logo to the panel corner. |

---

## Quick Start

Clone and run the automated installer:

```bash
git clone https://github.com/0xM4lik/WhiteSur-Glassy.git
cd WhiteSur-Glassy
./install.sh
```

---

## Installation Options

You can install all components interactively, or pass specific flags:

```bash
# Install everything (Themes, Extensions, YouTube Music patch, Blur my Shell presets)
./install.sh --all

# Install only GTK & Libadwaita themes
./install.sh --theme

# Install only recommended GNOME extensions
./install.sh --extensions

# Patch only YouTube Music Flatpak
./install.sh --youtube-music

# Apply recommended Blur my Shell dconf presets
./install.sh --blur-settings

# Check dependencies and system status without installing
./install.sh --check
```

---

## Configuration Breakdown

### 1. Libadwaita Overrides (`theme/libadwaita/gtk-WhiteSur-glassy.css`)
Libadwaita apps (Nautilus, Calculator, Software, Settings) read their styling from `~/.config/gtk-4.0/gtk.css`. WhiteSur-Glassy defines:

```css
/* Color Palette */
@define-color window_bg_color rgba(28, 28, 30, 0.75);
@define-color sidebar_bg_color rgba(22, 22, 24, 0.70);
@define-color headerbar_bg_color rgba(32, 32, 34, 0.75);

/* High-Contrast Opaque Elements */
@define-color window_fg_color #dedede;
@define-color headerbar_fg_color #ffffff;
@define-color card_bg_color rgba(255, 255, 255, 0.08);
```

To adjust overall window transparency, simply edit the alpha value (`0.75`) in `window_bg_color` and `sidebar_bg_color`.

### 2. YouTube Music Flatpak Setup & Patch (`apps/youtube-music/`)

> [!NOTE]
> The YouTube Music desktop app (`th-ch/youtube-music` / `pear-desktop`) is **not available on Flathub**. It is distributed as a standalone `.flatpak` bundle via GitHub Releases.

#### Installing YouTube Music Flatpak

You can install it either automatically via our script or manually from GitHub:

- **Automated (Recommended)**:
  ```bash
  # Automatically downloads the latest GitHub release bundle and installs it
  bash scripts/install-youtube-music.sh
  ```
  *(Or run `./install.sh` and accept the prompt to download and install it).*

- **Manual**:
  1. Download the latest `YouTube-Music-*-x86_64.flatpak` bundle from the [Pear Desktop / YouTube Music Releases](https://github.com/pear-devs/pear-desktop/releases).
  2. Install the downloaded bundle:
     ```bash
     flatpak install YouTube-Music-*-x86_64.flatpak
     ```

#### Applying the Glassy Transparency Patch

Once installed, apply the transparency patch:
```bash
./install.sh --youtube-music
```

What the patcher does:
- Unpacks the Flatpak's `app.asar` archive.
- Reconfigures `new BrowserWindow({ transparent: true, backgroundColor: "#00000000" })`.
- Adds `--enable-transparent-visuals` to Chromium launch arguments.
- Unlocks the built-in `transparent-player` plugin for Linux (`Platform.Linux`).
- Uses Flatpak's native `--app-path` parameter with a Btrfs CoW clone, consuming **0 bytes** duplicate disk storage.

You can fine-tune your desired background opacity directly inside the app:
> **YouTube Music** → **Plugins** → **Transparent Player** → **Opacity (10% - 100%)**

### 3. Blur my Shell Presets (`configs/blur-my-shell-glassy.dconf`)
Recommended extension settings include:
- Whitelist containing Nautilus, Calculator, Software, Ptyxis, Settings, and YouTube Music.
- Rounded blur pipelines with 14px corner radius.
- Gaussian blur settings tuned for optimal clarity (`sigma: 10`, `brightness: 1.0`).

---

## Testing in Container (Fedora)

To test the installation and validation in an isolated Fedora container without touching your local machine:

```bash
# Build test image
podman build -t whitesur-glassy-test -f test/Containerfile .

# Run test suite
podman run --rm whitesur-glassy-test
```

The test suite validates:
- [x] Balanced CSS syntax across all GTK 3, GTK 4, and GNOME Shell stylesheets.
- [x] Script syntax across installer, uninstaller, and extension installer.
- [x] Automated installer directory creation and symlink accuracy.
- [x] Desktop entry validity via `desktop-file-validate`.
- [x] Python asar packing and integrity calculation.
- [x] Complete, clean uninstaller rollback.

---

## Uninstallation / Rollback

To cleanly remove all modifications and revert to default themes:

```bash
./uninstall.sh
```

To roll back only YouTube Music:
```bash
./apps/youtube-music/restore-youtube-music.sh
```

---

## Credits & License

- **Original WhiteSur Theme**: Created by [vinceliuice](https://github.com/vinceliuice/WhiteSur-gtk-theme).
- **Blur my Shell Extension**: Created by [aunetx](https://github.com/aunetx/blur-my-shell).
- **Dash to Dock Extension**: Created by [michele_g](https://github.com/micheleg/dash-to-dock).
- **Logo Menu Extension**: Created by [Aryan_K](https://github.com/Aryan20/Logomenu).
- **User Themes Extension**: Maintained by [GNOME](https://gitlab.gnome.org/GNOME/gnome-shell-extensions).
- **YouTube Music Desktop App**: Maintained by [th-ch](https://github.com/th-ch/youtube-music).

Distributed under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for full details.
