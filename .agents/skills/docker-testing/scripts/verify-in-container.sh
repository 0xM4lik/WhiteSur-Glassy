#!/bin/bash
set -euo pipefail

echo "=== [1/11] Installing container test dependencies ==="
if command -v dnf >/dev/null 2>&1; then
    dnf install -y --setopt=install_weak_deps=False flatpak glib2 dconf python3 python3-gobject gobject-introspection gtk3 gtk4 >/dev/null
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y --no-install-recommends -qq flatpak libglib2.0-bin dconf-cli python3 python3-gi gir1.2-gtk-3.0 gir1.2-gtk-4.0 >/dev/null
fi

echo "=== [2/11] Verifying shell syntax and --help / --check / non-interactive guard ==="
bash -n /workspace/install.sh
bash -n /workspace/uninstall.sh
bash -n /workspace/theme/libadwaita/setup-libadwaita.sh
bash -n /workspace/scripts/setup-flatpak.sh
bash -n /workspace/scripts/setup-terminal.sh
bash -n /workspace/scripts/setup-shell.sh
bash -n /workspace/scripts/install-extensions.sh
bash -n /workspace/scripts/install-wallpapers.sh

/workspace/install.sh --help >/dev/null
CHECK_OUT="$(/workspace/install.sh --check)"
echo "$CHECK_OUT"
echo "$CHECK_OUT" | grep -q "flatpak: found"
echo "$CHECK_OUT" | grep -q "Linux Dynamic Wallpapers: not installed"
echo "$CHECK_OUT" | grep -q "Starship prompt:"

# Non-interactive --theme without --transparent or --tinted must fail cleanly
if /workspace/install.sh --theme < /dev/null 2>/dev/null; then
    echo "ERROR: install.sh --theme without variant should have failed in non-interactive mode!"
    exit 1
fi
echo "Verified non-interactive guard requires --transparent or --tinted."

echo "=== [3/11] Validating GTK 3 and GTK 4 CSS files with Gtk.CssProvider ==="
python3 - << 'PYEOF'
import sys
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk as Gtk3, GLib

gtk3_files = [
    "/workspace/theme/WhiteSur-Glassy-Transparent/gtk-3.0/gtk.css",
    "/workspace/theme/WhiteSur-Glassy-Tinted/gtk-3.0/gtk.css",
]
for path in gtk3_files:
    provider = Gtk3.CssProvider()
    errors = []
    def on_err(prov, section, err):
        if "/org/gnome/theme/gtk.css" not in err.message:
            errors.append(f"{path}:{section.get_start_line()+1}: {err.message}")
    provider.connect("parsing-error", on_err)
    try:
        provider.load_from_path(path)
    except GLib.Error:
        pass
    if errors:
        print("GTK3 CSS parsing errors:\n" + "\n".join(errors), file=sys.stderr)
        sys.exit(1)
    print(f"GTK3 CSS OK: {path}")
PYEOF

python3 - << 'PYEOF' 2>/dev/null
import sys
import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk as Gtk4

gtk4_files = [
    "/workspace/theme/WhiteSur-Glassy-Transparent/gtk-4.0/gtk.css",
    "/workspace/theme/WhiteSur-Glassy-Tinted/gtk-4.0/gtk.css",
    "/workspace/theme/libadwaita/gtk-WhiteSur-Glassy-Transparent.css",
    "/workspace/theme/libadwaita/gtk-WhiteSur-Glassy-Tinted.css",
]
for path in gtk4_files:
    provider = Gtk4.CssProvider()
    errors = []
    def on_err(prov, section, err):
        if "/org/gnome/theme/gtk.css" not in err.message:
            errors.append(f"{path}:{section.get_start_location().lines+1}: {err.message}")
    provider.connect("parsing-error", on_err)
    provider.load_from_path(path)
    if errors:
        print("GTK4 CSS parsing errors:\n" + "\n".join(errors), file=sys.stdout)
        sys.exit(1)
    print(f"GTK4 CSS OK: {path}")
PYEOF

echo "=== [4/11] Preparing pre-existing gtk.css and custom Flatpak override ==="
mkdir -p "$HOME/.config/gtk-4.0"
echo "/* pre-existing user css */" > "$HOME/.config/gtk-4.0/gtk.css"
mkdir -p "$HOME/.local/share/icons/WhiteSur"
flatpak override --user --env=CUSTOM_USER_VAR=keep_me

echo "=== [5/11] Testing install.sh --theme --transparent inside container ==="
/workspace/install.sh --theme --transparent < /dev/null

# Verify BOTH theme directories are installed
for tname in "WhiteSur-Glassy-Transparent" "WhiteSur-Glassy-Tinted"; do
    test -f "$HOME/.themes/$tname/gtk-3.0/gtk.css"
    test -f "$HOME/.themes/$tname/gtk-4.0/gtk.css"
    test -f "$HOME/.local/share/themes/$tname/gtk-3.0/gtk.css"
    test -f "$HOME/.local/share/themes/$tname/gtk-4.0/gtk.css"
done

# Verify Libadwaita files and backup
test -f "$HOME/.config/gtk-4.0/gtk.css.bak"
grep -q "pre-existing user css" "$HOME/.config/gtk-4.0/gtk.css.bak"
test -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Transparent.css"
test -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Tinted.css"
test -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Dark.css"
test -d "$HOME/.config/gtk-4.0/windows-assets"

# Verify symlinks are strictly relative and point to Transparent CSS
LINK_GTK="$(readlink "$HOME/.config/gtk-4.0/gtk.css")"
LINK_DARK="$(readlink "$HOME/.config/gtk-4.0/gtk-dark.css")"
echo "gtk.css symlink target (transparent): $LINK_GTK"
test "$LINK_GTK" = "gtk-WhiteSur-Glassy-Transparent.css"
test "$LINK_DARK" = "gtk-WhiteSur-Glassy-Transparent.css"

# Verify Flatpak overrides for Transparent
OVERRIDE_OUT="$(flatpak override --user --show)"
echo "$OVERRIDE_OUT" | grep -q "xdg-config/gtk-4.0:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-config/gtk-3.0:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-data/themes:ro"
echo "$OVERRIDE_OUT" | grep -q "~/.themes:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-data/icons:ro"
echo "$OVERRIDE_OUT" | grep -q "~/.icons:ro"
echo "$OVERRIDE_OUT" | grep -q "GTK_THEME=WhiteSur-Glassy-Transparent"
echo "$OVERRIDE_OUT" | grep -q "ICON_THEME=WhiteSur"
echo "$OVERRIDE_OUT" | grep -q "CUSTOM_USER_VAR=keep_me"

echo "=== [6/11] Simulating Flatpak sandbox mount & switching to --tinted ==="
mkdir -p /tmp/flatpak-sandbox/config
mv "$HOME/.config/gtk-4.0" /tmp/flatpak-sandbox/config/gtk-4.0
test ! -e "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Transparent.css"
head -n 5 /tmp/flatpak-sandbox/config/gtk-4.0/gtk.css | grep -q "@define-color window_bg_color transparent;"
mv /tmp/flatpak-sandbox/config/gtk-4.0 "$HOME/.config/gtk-4.0"

# Switch to Tinted variant via CLI
/workspace/install.sh --theme --tinted < /dev/null
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "gtk-WhiteSur-Glassy-Tinted.css"
test "$(readlink "$HOME/.config/gtk-4.0/gtk-dark.css")" = "gtk-WhiteSur-Glassy-Tinted.css"
head -n 5 "$HOME/.config/gtk-4.0/gtk.css" | grep -q "rgba(28, 28, 30, 0.75)"
flatpak override --user --show | grep -q "GTK_THEME=WhiteSur-Glassy-Tinted"

echo "=== [7/11] Testing interactive prompt selection (Option 1: Transparent, Option 2: Tinted) ==="
# Pipe Option 1 (Transparent), y (install theme), n (icons), n (shell), n (wallpapers)
printf "1\ny\nn\nn\nn\n" | /workspace/install.sh
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "gtk-WhiteSur-Glassy-Transparent.css"
flatpak override --user --show | grep -q "GTK_THEME=WhiteSur-Glassy-Transparent"

# Pipe Option 2 (Tinted), y (install theme), n (icons), n (shell), n (wallpapers)
printf "2\ny\nn\nn\nn\n" | /workspace/install.sh
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "gtk-WhiteSur-Glassy-Tinted.css"
flatpak override --user --show | grep -q "GTK_THEME=WhiteSur-Glassy-Tinted"

echo "=== [8/11] Running uninstall.sh inside container ==="
/workspace/uninstall.sh < /dev/null

# Verify both theme directories removed
for tname in "WhiteSur-Glassy-Transparent" "WhiteSur-Glassy-Tinted" "WhiteSur-glassy"; do
    test ! -d "$HOME/.themes/$tname"
    test ! -d "$HOME/.local/share/themes/$tname"
done

# Verify Libadwaita files removed and backup restored
test ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Transparent.css"
test ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Tinted.css"
test ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Dark.css"
test ! -d "$HOME/.config/gtk-4.0/windows-assets"
test -f "$HOME/.config/gtk-4.0/gtk.css"
test ! -L "$HOME/.config/gtk-4.0/gtk.css"
grep -q "pre-existing user css" "$HOME/.config/gtk-4.0/gtk.css"

# Verify Flatpak overrides cleaned up while preserving user's custom var
OVERRIDE_AFTER="$(flatpak override --user --show)"
echo "Flatpak overrides after uninstall:"
echo "$OVERRIDE_AFTER"
echo "$OVERRIDE_AFTER" | grep -q "CUSTOM_USER_VAR=keep_me"
! echo "$OVERRIDE_AFTER" | grep -q "GTK_THEME"
! echo "$OVERRIDE_AFTER" | grep -q "ICON_THEME"
! echo "$OVERRIDE_AFTER" | grep -q "xdg-config/gtk-4.0"
! echo "$OVERRIDE_AFTER" | grep -q "xdg-data/themes"

echo "=== [9/11] Testing standalone install.sh --flatpak ==="
mkdir -p "$HOME/.config/gtk-4.0"
touch "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Tinted.css"
ln -sf "$HOME/.config/gtk-4.0/gtk-WhiteSur-Glassy-Tinted.css" "$HOME/.config/gtk-4.0/gtk.css"

STANDALONE_OUT="$(/workspace/install.sh --flatpak < /dev/null)"
echo "$STANDALONE_OUT"
echo "$STANDALONE_OUT" | grep -q "Flatpak configuration complete"

# Verify symlink was converted to relative and active theme was auto-detected
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "gtk-WhiteSur-Glassy-Tinted.css"
flatpak override --user --show | grep -q "GTK_THEME=WhiteSur-Glassy-Tinted"
flatpak override --user --show | grep -q "xdg-config/gtk-4.0:ro"

echo "=== [10/11] Testing standalone install.sh --wallpapers and uninstall ==="
MOCK_WP_SRC="/tmp/mock-dynamic-wallpapers"
mkdir -p "$MOCK_WP_SRC/Dynamic_Wallpapers/TestTheme" "$MOCK_WP_SRC/xml"
touch "$MOCK_WP_SRC/Dynamic_Wallpapers/TestTheme/1.jpg"
cat << 'EOF' > "$MOCK_WP_SRC/Dynamic_Wallpapers/TestTheme.xml"
<wallpaper><name>TestTheme</name></wallpaper>
EOF
cat << 'EOF' > "$MOCK_WP_SRC/xml/TestTheme.xml"
<?xml version="1.0"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper>
    <name>TestTheme</name>
    <filename>/usr/share/backgrounds/Dynamic_Wallpapers/TestTheme.xml</filename>
  </wallpaper>
</wallpapers>
EOF
cat << 'EOF' > "$MOCK_WP_SRC/install.sh"
#!/bin/bash
if [[ -d /usr/share/backgrounds/Dynamic_Wallpapers ]]; then
    sudo rm -r /usr/share/backgrounds/Dynamic_Wallpapers
fi
sudo mkdir -p /usr/share/backgrounds/
sudo mkdir -p /usr/share/gnome-background-properties/
sudo cp -r "$(pwd)/Dynamic_Wallpapers" /usr/share/backgrounds/Dynamic_Wallpapers
sudo cp "$(pwd)/xml/"* /usr/share/gnome-background-properties/
EOF
chmod +x "$MOCK_WP_SRC/install.sh"

WP_INSTALL_OUT="$(DYNAMIC_WALLPAPERS_SRC="$MOCK_WP_SRC" /workspace/install.sh --wallpapers < /dev/null)"
echo "$WP_INSTALL_OUT"
echo "$WP_INSTALL_OUT" | grep -q "Linux Dynamic Wallpapers installation complete"

test -d "/usr/share/backgrounds/Dynamic_Wallpapers/TestTheme"
test -f "/usr/share/backgrounds/Dynamic_Wallpapers/TestTheme.xml"
test -f "/usr/share/gnome-background-properties/TestTheme.xml"

# Non-interactive uninstall preserves wallpapers
/workspace/uninstall.sh < /dev/null
test -d "/usr/share/backgrounds/Dynamic_Wallpapers"
test -f "/usr/share/gnome-background-properties/TestTheme.xml"

# Interactive uninstall: answer 'y' to icons (if present) and 'y' to wallpapers
printf "y\ny\n" | /workspace/uninstall.sh
test ! -d "/usr/share/backgrounds/Dynamic_Wallpapers"
test ! -f "/usr/share/gnome-background-properties/TestTheme.xml"

echo "=== [11/11] Testing standalone install.sh --shell and uninstall restoration ==="
echo "# custom user bashrc" > "$HOME/.bashrc"
SHELL_INSTALL_OUT="$(/workspace/install.sh --shell < /dev/null)"
echo "$SHELL_INSTALL_OUT"
echo "$SHELL_INSTALL_OUT" | grep -q "Shell configuration complete"

# Verify .bashrc was updated with Starship prompt support
grep -q "starship init bash" "$HOME/.bashrc"

# Verify backup was created with the previous custom bashrc
LATEST_BAK="$(ls -t "$HOME"/.bashrc.pre-whitesur-*.bak 2>/dev/null | head -n 1)"
test -f "$LATEST_BAK"
grep -q "custom user bashrc" "$LATEST_BAK"

# Verify uninstall restores the backup
/workspace/uninstall.sh < /dev/null
grep -q "custom user bashrc" "$HOME/.bashrc"
! grep -q "starship init bash" "$HOME/.bashrc"

echo "=== ALL CONTAINER TESTS PASSED SUCCESSFULLY ==="
