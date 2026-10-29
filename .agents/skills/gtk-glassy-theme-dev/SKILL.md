---
name: gtk-glassy-theme-dev
description: >-
  Guide and reference for developing, debugging, and extending GTK 3, GTK 4,
  Libadwaita, GNOME Shell, and Ptyxis terminal transparency in WhiteSur-Glassy
  (both WhiteSur-Glassy-Transparent and WhiteSur-Glassy-Tinted themes).
---

# GTK & Libadwaita Glassy Theme Development

## Theme Architecture Overview

WhiteSur-Glassy ships two individual themes that are both installed to `~/.themes` and `~/.local/share/themes` (with Libadwaita overrides in `~/.config/gtk-4.0/`):

1. **`WhiteSur-Glassy-Transparent` (100% Fully Transparent)**
   - Files:
     - `theme/WhiteSur-Glassy-Transparent/gtk-3.0/gtk.css`
     - `theme/WhiteSur-Glassy-Transparent/gtk-4.0/gtk.css`
     - `theme/WhiteSur-Glassy-Transparent/gnome-shell/gnome-shell.css`
     - `theme/libadwaita/gtk-WhiteSur-Glassy-Transparent.css`
   - Behavior: Every window, view, headerbar, sidebar, dialog, and popover has `background-color: transparent;` (`rgba(0, 0, 0, 0)`) so Blur my Shell's background blur shines through with 0% tint while text and icons remain 100% opaque (`#dedede` / `#ffffff`).

2. **`WhiteSur-Glassy-Tinted` (75% Tinted Glass)**
   - Files:
     - `theme/WhiteSur-Glassy-Tinted/gtk-3.0/gtk.css`
     - `theme/WhiteSur-Glassy-Tinted/gtk-4.0/gtk.css`
     - `theme/WhiteSur-Glassy-Tinted/gnome-shell/gnome-shell.css`
     - `theme/libadwaita/gtk-WhiteSur-Glassy-Tinted.css`
   - Behavior: Window backgrounds use `rgba(28, 28, 30, 0.75)`, sidebars use `rgba(22, 22, 24, 0.70)`, and floating dialogs/popovers use `rgba(32, 32, 34, 0.85)`, while inner views and headerbars remain `transparent` to avoid nested opacity stacking.

---

## Key Rules for Extending App Transparency

### 1. Keep `gtk-4.0/gtk.css` and `theme/libadwaita/gtk-WhiteSur-Glassy-*.css` in Sync
Every rule added to `theme/libadwaita/gtk-WhiteSur-Glassy-Transparent.css` (and `Tinted.css`) must also be mirrored in `theme/WhiteSur-Glassy-Transparent/gtk-4.0/gtk.css` (and `WhiteSur-Glassy-Tinted/gtk-4.0/gtk.css`).
The **only** difference between the Libadwaita file and the `gtk-4.0/gtk.css` file is line 37:
- `theme/libadwaita/gtk-WhiteSur-Glassy-*.css` imports `@import url("gtk-WhiteSur-Dark.css");`
- `theme/WhiteSur-Glassy-*/gtk-4.0/gtk.css` imports `@import url("resource:///org/gnome/theme/gtk.css");`

### 2. Avoid Nested Opacity Stacking
In **`WhiteSur-Glassy-Tinted`**, the 75% tint (`@window_bg_color`) must be applied **only once** at the root `window` / `window.background.csd` surface (or `.sidebar-pane` for sidebars).
All inner containers (`scrolledwindow`, `viewport`, `stack`, `leaflet`, `flap`, `toolbarview`, `toolbarview > .content`, `navigation-view`, `navigation-split-view > .content`, `overlay-split-view > .content`, `.view`, `listview`, `gridview`, `columnview`) **must** have:
```css
background-color: transparent;
background-image: none;
```
If an inner container also uses `@window_bg_color`, two `0.75` alpha layers stack to $1 - (1 - 0.75)^2 = 93.75\%$ opacity, ruining the glass effect.

### 3. GTK 3 & GTK 4 CSS Does Not Support `!important`
- **GNOME Shell (`gnome-shell.css`)** uses St (Stage Widget) CSS, which **does** support `!important`.
- **GTK 3 and GTK 4 (`gtk.css`)** do **not** support `!important` (it triggers a `Gtk.CssProvider` parsing error). Always use selector specificity instead of `!important` in GTK CSS files.

### 4. How Ptyxis Terminal (`org.gnome.Ptyxis`) Works
Ptyxis (`ptyxis-window-dressing.c`) registers a dynamic per-window `GtkCssProvider` at priority `801` (`GTK_STYLE_PROVIDER_PRIORITY_USER + 1`), which is higher than `~/.config/gtk-4.0/gtk.css` (priority `800`).
Ptyxis injects:
```css
window.<dynamic-id> { color: <Foreground>; background-color: alpha(<Background>, <opacity>); }
window.<dynamic-id> .window-contents > revealer windowhandle { color: <TitlebarForeground>; background-color: <TitlebarBackground>; }
window.<dynamic-id>:backdrop .window-contents revealer > windowhandle { color: mix(<TitlebarForeground>,<Background>,.025); background-color: mix(<TitlebarBackground>,<Background>,.99); }
```
- Because `:backdrop` mixes `TitlebarBackground` and `Background` at 99% **without** multiplying by profile `opacity`, setting a non-transparent `Background` in `WhiteSur-Glassy.palette` causes unfocused Ptyxis titlebars to turn solid.
- Therefore, `configs/terminal/WhiteSur-Glassy.palette` keeps `Background=rgba(0,0,0,0)` and `TitlebarBackground=rgba(0,0,0,0)`.
- Ptyxis's priority-801 CSS does **not** set `background-color` on `window.background.csd > .window-contents`.
  - In `WhiteSur-Glassy-Transparent`, `window.background.csd > .window-contents` is `transparent` (100% transparent).
  - In `WhiteSur-Glassy-Tinted`, `window.background.csd > .window-contents` is `@window_bg_color` (`rgba(28, 28, 30, 0.75)`), giving the entire terminal window (including focused and unfocused headerbars) a single uniform 75% tint.

### 5. Adding Support for New Applications
1. Identify the app's WM class / desktop ID and add it to `whitelist` in `configs/blur-my-shell-glassy.dconf` if needed (note: `enable-all=true` is enabled by default).
2. Inspect the app's widget tree (using `GTK_DEBUG=interactive <app>` on the host or inspecting UI files/strings in a container).
3. Add inner container selectors with `background-color: transparent; background-image: none;` to both `WhiteSur-Glassy-Transparent` and `WhiteSur-Glassy-Tinted` CSS files.
4. Always run the container test suite (which validates GTK 3 and GTK 4 CSS via `Gtk.CssProvider`) before finishing.
