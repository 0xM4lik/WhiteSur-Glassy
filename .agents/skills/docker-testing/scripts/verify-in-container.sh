#!/bin/bash
set -euo pipefail

echo "=== [1/6] Installing container test dependencies ==="
if command -v dnf >/dev/null 2>&1; then
    dnf install -y --setopt=install_weak_deps=False flatpak glib2 dconf python3 >/dev/null
elif command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq && apt-get install -y --no-install-recommends -qq flatpak libglib2.0-bin dconf-cli python3 >/dev/null
fi

echo "=== [2/6] Verifying syntax and --help / --check flags ==="
bash -n /workspace/install.sh
bash -n /workspace/uninstall.sh
bash -n /workspace/theme/libadwaita/setup-libadwaita.sh
bash -n /workspace/scripts/setup-flatpak.sh

/workspace/install.sh --help >/dev/null
CHECK_OUT="$(/workspace/install.sh --check)"
echo "$CHECK_OUT"
echo "$CHECK_OUT" | grep -q "flatpak: found"

echo "=== [3/6] Preparing pre-existing gtk.css and custom Flatpak override ==="
mkdir -p "$HOME/.config/gtk-4.0"
echo "/* pre-existing user css */" > "$HOME/.config/gtk-4.0/gtk.css"
mkdir -p "$HOME/.local/share/icons/WhiteSur"
flatpak override --user --env=CUSTOM_USER_VAR=keep_me

echo "=== [4/6] Running install.sh --theme inside container ==="
/workspace/install.sh --theme < /dev/null

# Verify theme directories
test -f "$HOME/.themes/WhiteSur-glassy/gtk-3.0/gtk.css"
test -f "$HOME/.themes/WhiteSur-glassy/gtk-4.0/gtk.css"
test -f "$HOME/.local/share/themes/WhiteSur-glassy/gtk-3.0/gtk.css"
test -f "$HOME/.local/share/themes/WhiteSur-glassy/gtk-4.0/gtk.css"

# Verify Libadwaita files and backup
test -f "$HOME/.config/gtk-4.0/gtk.css.bak"
grep -q "pre-existing user css" "$HOME/.config/gtk-4.0/gtk.css.bak"
test -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css"
test -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Dark.css"
test -d "$HOME/.config/gtk-4.0/windows-assets"

# Verify symlinks are strictly relative (crucial for Flatpak sandbox mounting)
LINK_GTK="$(readlink "$HOME/.config/gtk-4.0/gtk.css")"
LINK_DARK="$(readlink "$HOME/.config/gtk-4.0/gtk-dark.css")"
echo "gtk.css symlink target: $LINK_GTK"
echo "gtk-dark.css symlink target: $LINK_DARK"
test "$LINK_GTK" = "gtk-WhiteSur-glassy.css"
test "$LINK_DARK" = "gtk-WhiteSur-glassy.css"

# Verify Flatpak overrides
OVERRIDE_OUT="$(flatpak override --user --show)"
echo "Flatpak overrides:"
echo "$OVERRIDE_OUT"
echo "$OVERRIDE_OUT" | grep -q "xdg-config/gtk-4.0:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-config/gtk-3.0:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-data/themes:ro"
echo "$OVERRIDE_OUT" | grep -q "~/.themes:ro"
echo "$OVERRIDE_OUT" | grep -q "xdg-data/icons:ro"
echo "$OVERRIDE_OUT" | grep -q "~/.icons:ro"
echo "$OVERRIDE_OUT" | grep -q "GTK_THEME=WhiteSur-glassy"
echo "$OVERRIDE_OUT" | grep -q "ICON_THEME=WhiteSur"
echo "$OVERRIDE_OUT" | grep -q "CUSTOM_USER_VAR=keep_me"

echo "=== [5/6] Simulating Flatpak sandbox mount for xdg-config/gtk-4.0 ==="
mkdir -p /tmp/flatpak-sandbox/config
mv "$HOME/.config/gtk-4.0" /tmp/flatpak-sandbox/config/gtk-4.0
# At this point $HOME/.config/gtk-4.0 does NOT exist, mimicking Flatpak sandbox
test ! -e "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css"
# Relative symlink must still resolve and read CSS content!
head -n 5 /tmp/flatpak-sandbox/config/gtk-4.0/gtk.css | grep -q "window_bg_color"
head -n 5 /tmp/flatpak-sandbox/config/gtk-4.0/gtk-dark.css | grep -q "window_bg_color"
# Move back for uninstall test
mv /tmp/flatpak-sandbox/config/gtk-4.0 "$HOME/.config/gtk-4.0"

echo "=== [6/6] Running uninstall.sh inside container ==="
/workspace/uninstall.sh < /dev/null

# Verify theme directories removed
test ! -d "$HOME/.themes/WhiteSur-glassy"
test ! -d "$HOME/.local/share/themes/WhiteSur-glassy"

# Verify Libadwaita files removed and backup restored
test ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css"
test ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-Dark.css"
test ! -d "$HOME/.config/gtk-4.0/windows-assets"
test -f "$HOME/.config/gtk-4.0/gtk.css"
test ! -L "$HOME/.config/gtk-4.0/gtk.css"
grep -q "pre-existing user css" "$HOME/.config/gtk-4.0/gtk.css"

# Verify Flatpak overrides cleaned up without leaving !deny rules or empty vars, while preserving user's custom var
OVERRIDE_AFTER="$(flatpak override --user --show)"
echo "Flatpak overrides after uninstall:"
echo "$OVERRIDE_AFTER"
echo "$OVERRIDE_AFTER" | grep -q "CUSTOM_USER_VAR=keep_me"
! echo "$OVERRIDE_AFTER" | grep -q "GTK_THEME"
! echo "$OVERRIDE_AFTER" | grep -q "ICON_THEME"
! echo "$OVERRIDE_AFTER" | grep -q "xdg-config/gtk-4.0"
! echo "$OVERRIDE_AFTER" | grep -q "xdg-data/themes"

echo "=== [7/7] Testing standalone install.sh --flatpak ==="
# Setup a dummy gtk-4.0 dir with an absolute symlink to simulate pre-existing setup
mkdir -p "$HOME/.config/gtk-4.0"
touch "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css"
ln -sf "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css" "$HOME/.config/gtk-4.0/gtk.css"
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css"

# Run install.sh --flatpak
STANDALONE_OUT="$(/workspace/install.sh --flatpak < /dev/null)"
echo "$STANDALONE_OUT"
echo "$STANDALONE_OUT" | grep -q "Flatpak configuration complete"

# Verify symlink was converted to relative
test "$(readlink "$HOME/.config/gtk-4.0/gtk.css")" = "gtk-WhiteSur-glassy.css"

# Verify overrides applied
flatpak override --user --show | grep -q "GTK_THEME=WhiteSur-glassy"
flatpak override --user --show | grep -q "xdg-config/gtk-4.0:ro"

echo "=== ALL CONTAINER TESTS PASSED SUCCESSFULLY ==="
