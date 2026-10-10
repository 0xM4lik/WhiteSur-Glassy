# Blur my Shell Presets & Configuration

This directory contains recommended and tested settings for the **[Blur my Shell](https://github.com/aunetx/blur-my-shell)** GNOME Shell extension.

---

## What is in `blur-my-shell-glassy.dconf`?

- **Application Whitelist**: Whitelists key applications (`org.gnome.Nautilus`, `org.gnome.Calculator`, `org.gnome.Software`, `com.github.th_ch.youtube_music`, `org.gnome.Ptyxis`, `org.gnome.Settings`, etc.) so the shell renders gaussian blur actors directly behind their translucent surfaces.
- **Blur Pipelines**: Configures rounded corner pipelines (14px corner radius) with standard sigma (`sigma: 10`, `brightness: 1.0`).
- **Panel & Dock Blur**: Configures matching frosted glass effects on Dash to Dock and the top panel.

---

## How to Apply

### Automated via Installer
```bash
./install.sh --blur-settings
```

### Manual via `dconf`
```bash
dconf load /org/gnome/shell/extensions/blur-my-shell/ < blur-my-shell-glassy.dconf
```
