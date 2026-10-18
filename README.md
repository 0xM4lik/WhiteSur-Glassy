# WhiteSur-Glassy

A modified version of the WhiteSur GTK and GNOME Shell theme with transparency support for [Blur my Shell](https://github.com/aunetx/blur-my-shell).

Normally, applying Blur my Shell to GTK4 and Libadwaita apps doesn't work well because GNOME apps have solid backgrounds, or global opacity tools wash out the text and buttons. This theme makes window backgrounds 75% transparent so Mutter can blur behind them, while keeping text, icons, and buttons fully opaque and easy to read.

## Features

- **Transparent app backgrounds**: 75% background transparency on GTK3, GTK4, and Libadwaita apps (Files, Settings, Calculator, Software).
- **Readable text & controls**: Text, icons, and inputs stay 100% opaque.
- **No button borders**: Removes harsh button outlines so buttons look natural on glass backgrounds.
- **macOS window controls**: Left-aligned traffic light buttons (close, minimize, maximize) across GTK and Libadwaita.
- **Glassy Quick Settings**: Audio device picker and submenus match the rest of the blurred panel.
- **Terminal transparency**: Automatically sets 75% background opacity in Ptyxis and GNOME Terminal.
- **Shell config**: Clean `.bashrc` template that installs and configures the Starship prompt.
- **Extension installer**: One-command setup for Blur my Shell, Dash to Dock, Logo Menu, and User Themes.
- **Rounded dynamic corners**: Automatically installs [`gnome-rounded-blur`](https://github.com/aunetx/blur-my-shell/blob/master/scripts/GUIDE.md) so Blur my Shell renders rounded window corners with dynamic blur out of the box.

## Quick Start

Clone the repo and run the installer:

```bash
git clone https://github.com/0xM4lik/WhiteSur-Glassy.git
cd WhiteSur-Glassy
./install.sh
```

Running `./install.sh` without flags gives you an interactive prompt where you can choose what to set up.

## Installation Flags

You can also pass flags directly:

```bash
# Install everything (theme, icons, extensions, rounded blur library, terminal, shell, presets)
./install.sh --all

# Only install the GTK/Libadwaita theme and window buttons
./install.sh --theme

# Only configure Flatpak overrides (GTK 3/4 theme, Libadwaita, icons)
./install.sh --flatpak

# Only install WhiteSur icons
./install.sh --icons

# Only install GNOME extensions and gnome-rounded-blur
./install.sh --extensions

# Only install gnome-rounded-blur (rounded dynamic corners for Blur my Shell)
./install.sh --rounded-blur

# Set terminal transparency to 75% (Ptyxis / GNOME Terminal)
./install.sh --terminal

# Install shell config (.bashrc + Starship prompt)
./install.sh --shell

# Apply extension presets (Blur my Shell, Dash to Dock, Logo Menu)
./install.sh --configs

# Check system dependencies
./install.sh --check
```

## Recommended Extensions

The installer can automatically download, compile, and enable these extensions:

- **[User Themes](https://extensions.gnome.org/extension/19/user-themes/)**: Needed to load the shell theme from `~/.themes`.
- **[Blur my Shell](https://extensions.gnome.org/extension/3193/blur-my-shell/)**: Blurs the desktop wallpaper behind windows and the panel. Includes automated installation of [`gnome-rounded-blur`](https://github.com/aunetx/blur-my-shell/blob/master/scripts/GUIDE.md) to enable rounded dynamic corners out of the box.
- **[Dash to Dock](https://extensions.gnome.org/extension/307/dash-to-dock/)**: Dock at the bottom of the screen.
- **[Logo Menu](https://extensions.gnome.org/extension/4451/logo-menu/)**: Apple logo menu in the top-left corner.

## Uninstall

To remove the theme and restore default settings:

```bash
./uninstall.sh
```

This reverts your GTK and icon themes back to Adwaita, restores your window button layout, resets terminal opacity back to opaque (1.0), restores your original `~/.bashrc` from backup, and gives you the option to remove installed icons and extensions.

## Credits & License

- Based on [WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) and [WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) by vinceliuice.
- Uses [Blur my Shell](https://github.com/aunetx/blur-my-shell) by aunetx.

Licensed under [GPL-3.0](LICENSE).
