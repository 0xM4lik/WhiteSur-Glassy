# Extension & System Presets

This directory contains settings for GNOME extensions, terminal transparency, and bash.

## Files

- **`blur-my-shell-glassy.dconf`**: Blur my Shell settings with application whitelisting (Nautilus, Software, Settings, Calculator, Ptyxis), 14px rounded window corners, and dock blur.
- **`dash-to-dock-glassy.dconf`**: Floating dock centered at the bottom of the screen with 80% opacity and 48px icons.
- **`logo-menu-glassy.dconf`**: Places the Apple logo in the top-left panel corner.
- **`ptyxis-glassy.dconf`**: Ptyxis profile setting window opacity to 0.75 (75%).
- **`shell/bashrc`**: `.bashrc` template with Starship prompt support and sensible aliases.

## Applying Settings

Run the installer:
```bash
./install.sh --configs
```

Or load them individually:
```bash
# Terminal transparency:
./install.sh --terminal

# Shell config (.bashrc + Starship):
./install.sh --shell

# Or load directly using dconf:
dconf load /org/gnome/shell/extensions/blur-my-shell/ < blur-my-shell-glassy.dconf
dconf load /org/gnome/shell/extensions/dash-to-dock/ < dash-to-dock-glassy.dconf
dconf load /org/gnome/shell/extensions/Logo-menu/ < logo-menu-glassy.dconf
```
