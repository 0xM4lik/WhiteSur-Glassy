<div align="center">

# WhiteSur-Glassy

**A curated frosted-glass desktop theme suite for GNOME & Blur my Shell.**

Translucent GTK 3, GTK 4, and Libadwaita application styling with sharp, 100% readable text, authentic Apple window traffic lights, and glassy terminal transparency.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GNOME](https://img.shields.io/badge/GNOME-45%20|%2046%20|%2047%20|%2050+-3584e4.svg?logo=gnome)](https://www.gnome.org/)
[![Libadwaita](https://img.shields.io/badge/Libadwaita-Supported-brightgreen.svg)](https://gitlab.gnome.org/GNOME/libadwaita)

</div>

---

## Overview

### The Problem
When using the [Blur my Shell](https://github.com/aunetx/blur-my-shell) extension on GNOME, window transparency is often frustrating:
- **Global window opacity hacks** make everything transparent — including text, buttons, and icons — making applications difficult to read.
- **Stock GTK and Libadwaita applications** (like Files/Nautilus, Calculator, and Software) hardcode multiple solid background layers, rendering as flat opaque grey boxes even when whitelisted.
- **Default terminals** require manual diving into preferences to configure opacity.
- **Stock button outlines** create distracting borders on translucent frosted glass backgrounds.

### The Solution: WhiteSur-Glassy
**WhiteSur-Glassy** transforms your desktop into an authentic frosted-glass interface:
1. **~75% Translucent Background Surfaces**: Window backdrops, sidebars, and navigation bars allow desktop wallpaper blur to shine through.
2. **100% Opaque & Crisp Foregrounds**: Text, icons, buttons, and inputs remain sharp, high-contrast, and fully readable with zero borders.
3. **No Double-Layering**: Deep container hierarchies in Nautilus and Libadwaita are stripped of opaque background overrides.
4. **Apple Window Traffic Lights**: High-resolution borderless circular traffic light buttons (Close, Minimize, Maximize) placed on the top left.
5. **Glassy Terminal Transparency**: Automatically configures 75% background opacity for modern **Ptyxis** and traditional **GNOME Terminal**.
6. **Sleek Shell Configuration**: Portable `.bashrc` with cross-shell [Starship](https://starship.rs/) prompt integration.
7. **Automated GNOME Extensions**: Installs and activates Dash to Dock, Blur my Shell, Logo Menu, and User Themes automatically.

---

## Visual & Opacity Matrix

| Application / Surface | Rendered Opacity | Background Style | Text & Controls |
| :--- | :---: | :--- | :---: |
| **Nautilus (Files) Grid & Lists** | **75%** (`rgba(28, 28, 30, 0.75)`) | Frosted glass with desktop blur | 100% Opaque |
| **Nautilus Sidebar** | **70%** (`rgba(22, 22, 24, 0.70)`) | Deep glass contrast | 100% Opaque |
| **GNOME Calculator** | **75%** (`rgba(28, 28, 30, 0.75)`) | Translucent canvas + frosted display card | 100% Opaque |
| **GNOME Software** | **75%** (`rgba(28, 28, 30, 0.75)`) | Glass backdrop with full Mutter blur | 100% Opaque |
| **Ptyxis / GNOME Terminal** | **75%** (`opacity=0.75`) | Frosted glassy terminal window | 100% Opaque |
| **Window Traffic Lights** | — | Clean macOS circular dots (zero border) | 100% Opaque |
| **Standard UI Buttons** | — | Borderless frosted pills (no sharp borders) | 100% Opaque |

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
# Install everything (Theme, Traffic Lights, Icons, Extensions, Terminal, Shell, Presets)
./install.sh --all

# Install GTK & Libadwaita glassy theme + Apple window traffic lights
./install.sh --theme

# Install WhiteSur Apple-style icon theme (authentic macOS icons)
./install.sh --icons

# Install recommended GNOME extensions (Dash to Dock, Blur my Shell, Logo Menu, User Themes)
./install.sh --extensions

# Configure 75% terminal transparency (Ptyxis & GNOME Terminal)
./install.sh --terminal

# Install clean glassy shell configuration (.bashrc with Starship prompt)
./install.sh --shell

# Apply recommended extension presets (Dash to Dock, Blur my Shell, Logo Menu) & Terminal
./install.sh --configs

# Check dependencies and system status without installing
./install.sh --check
```

---

## Configuration Breakdown

### 1. Libadwaita Overrides & Apple Window Controls (`theme/libadwaita/`)
Libadwaita apps (Nautilus, Calculator, Software, Settings) read their styling from `~/.config/gtk-4.0/gtk.css`:

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

- **Apple Window Traffic Lights**: Window controls are aligned to the top-left (`close,minimize,maximize:`) with borderless, circular macOS traffic lights (Red/Yellow/Green dots with hover symbols).
- **Borderless Buttons**: Buttons render as clean, borderless frosted pills without harsh outlines.

### 2. WhiteSur Icon Theme (`scripts/install-icons.sh`)
- Automated installer for [vinceliuice/WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme).
- Installs authentic Apple macOS Big Sur/Monterey/Sonoma icons (Finder smiling face, App Store, and high-DPI application icons).

### 3. Glassy Terminal Transparency (`scripts/setup-terminal.sh`)
- Automatically detects **Ptyxis** (Fedora default) and configures profile opacity to `0.75`.
- Automatically detects **GNOME Terminal** (Ubuntu/Debian/Arch) and sets background transparency to 25% (75% opacity).

### 4. Shell Configuration (`configs/shell/bashrc`)
- Clean, modular `.bashrc` template.
- Seamless integration with [Starship](https://starship.rs/) prompt.
- Sourcing for modular `~/.bashrc.d/` snippets.
- Silences noisy virtualenv prompt prefixes.

### 5. Extension Configurations (`configs/`)

- **Blur my Shell (`configs/blur-my-shell-glassy.dconf`)**:
  - Whitelist containing Nautilus, Calculator, Software, Ptyxis, Settings, and Text Editor.
  - Dual pipelines: rounded blur for dock and popups (`corner-radius: 24`, `sigma: 10`), standard gaussian blur for windows (`sigma: 10`, `brightness: 1.0`).
- **Dash to Dock (`configs/dash-to-dock-glassy.dconf`)**:
  - Centered macOS-style floating dock at bottom of the primary monitor.
  - 80% background opacity (`0.80`), 48px icons, intelligent auto-hide, and minimized animations.
- **Logo Menu (`configs/logo-menu-glassy.dconf`)**:
  - Apple symbolic logo on the top-left panel corner.
  - Quick launcher configured for system monitoring (`Resources`).

---

## Uninstallation / Rollback

To cleanly remove all modifications and revert to default themes:

```bash
./uninstall.sh
```

---

## Credits & License

- **Original WhiteSur Theme**: Created by [vinceliuice](https://github.com/vinceliuice/WhiteSur-gtk-theme).
- **WhiteSur Icon Theme**: Created by [vinceliuice](https://github.com/vinceliuice/WhiteSur-icon-theme).
- **Blur my Shell Extension**: Created by [aunetx](https://github.com/aunetx/blur-my-shell).
- **Dash to Dock Extension**: Created by [michele_g](https://github.com/micheleg/dash-to-dock).
- **Logo Menu Extension**: Created by [Aryan_K](https://github.com/Aryan20/Logomenu).
- **User Themes Extension**: Maintained by [GNOME](https://gitlab.gnome.org/GNOME/gnome-shell-extensions).

Distributed under the **GNU General Public License v3.0 (GPL-3.0)**. See [LICENSE](LICENSE) for full details.
