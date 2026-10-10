# WhiteSur-Glassy Presets & Configurations

This directory contains recommended, pre-tested configuration presets for extensions, terminal transparency, and shell customization.

---

## Included Configurations

1. **Blur my Shell (`blur-my-shell-glassy.dconf`)**:
   - Whitelists key applications (`org.gnome.Nautilus`, `org.gnome.Calculator`, `org.gnome.Software`, `org.gnome.Ptyxis`, `org.gnome.Settings`, etc.) so the shell renders gaussian blur actors directly behind their translucent surfaces.
   - Rounded corner pipelines (14px corner radius) with standard sigma (`sigma: 10`, `brightness: 1.0`).
   - Matching frosted glass effects on Dash to Dock and the top panel.

2. **Dash to Dock (`dash-to-dock-glassy.dconf`)**:
   - Centered floating bottom dock on the primary display.
   - Frosted 80% background opacity (`0.80`), 48px icons, intelligent auto-hide, and smooth animations.

3. **Logo Menu (`logo-menu-glassy.dconf`)**:
   - Apple symbolic logo on the top panel corner (`menu-button-icon-image=0`).
   - Clean macOS-style system menu launcher.

4. **Ptyxis Terminal (`ptyxis-glassy.dconf`)**:
   - Dark interface style with 75% window background opacity (`opacity=0.75`).

5. **Shell Configuration (`shell/bashrc`)**:
   - Clean, portable `.bashrc` template with Starship cross-shell prompt integration, modular `~/.bashrc.d/` sourcing, and clean prompt environment.

---

## How to Apply

### Automated via Installer
```bash
./install.sh --configs
```
Or apply individually:
```bash
# Terminal transparency:
./install.sh --terminal

# Shell prompt configuration:
./install.sh --shell
```

### Manual via `dconf`
```bash
dconf load /org/gnome/shell/extensions/blur-my-shell/ < blur-my-shell-glassy.dconf
dconf load /org/gnome/shell/extensions/dash-to-dock/ < dash-to-dock-glassy.dconf
dconf load /org/gnome/shell/extensions/Logo-menu/ < logo-menu-glassy.dconf
```
