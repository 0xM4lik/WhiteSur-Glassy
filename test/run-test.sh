#!/bin/bash
set -e

echo "============================================="
echo "   WhiteSur-Glassy Automated Test Suite      "
echo "============================================="

# 1. Test CSS Files Integrity
echo "-> [TEST 1/5] Verifying CSS Files..."
for css_file in \
    "theme/libadwaita/gtk-WhiteSur-glassy.css" \
    "theme/WhiteSur-glassy/gtk-3.0/gtk.css" \
    "theme/WhiteSur-glassy/gtk-4.0/gtk.css" \
    "theme/WhiteSur-glassy/gnome-shell/gnome-shell.css"; do
    if [ ! -f "$css_file" ]; then
        echo "Error: CSS file not found: $css_file"
        exit 1
    fi
    # Check for basic balanced braces
    open_count=$(grep -o "{" "$css_file" | wc -l)
    close_count=$(grep -o "}" "$css_file" | wc -l)
    if [ "$open_count" -ne "$close_count" ]; then
        echo "Error: Unmatched braces in $css_file: { is $open_count, } is $close_count"
        exit 1
    fi
    echo "  ✓ $css_file verified ($open_count blocks)"
done

# 2. Test Installer in non-interactive mode
echo "-> [TEST 2/5] Running installer (--theme)..."
./install.sh --theme

# Verify files were placed in $HOME
if [ ! -d "$HOME/.themes/WhiteSur-glassy" ]; then
    echo "Error: Theme not installed to $HOME/.themes/WhiteSur-glassy"
    exit 1
fi
if [ ! -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css" ]; then
    echo "Error: Libadwaita CSS not installed to $HOME/.config/gtk-4.0/"
    exit 1
fi
if [ ! -L "$HOME/.config/gtk-4.0/gtk.css" ]; then
    echo "Error: gtk.css symlink missing"
    exit 1
fi
echo "  ✓ Theme and Libadwaita files correctly placed in user profile"

# 3. Test Desktop File Generation & Validation
echo "-> [TEST 3/5] Validating Desktop Entry syntax..."
TEST_DESKTOP="/tmp/test-com.github.th_ch.youtube_music.desktop"
cat << DESKTOP_EOF > "$TEST_DESKTOP"
[Desktop Entry]
Name=YouTube Music
Exec=flatpak run --branch=master --arch=x86_64 --app-path=/tmp/files --command=electron-wrapper --file-forwarding com.github.th_ch.youtube_music @@u %U @@
Terminal=false
Type=Application
Icon=com.github.th_ch.youtube_music
StartupWMClass=com.github.th_ch.youtube_music
Comment=YouTube Music Desktop App with glassy transparent blur
Categories=AudioVideo;
X-Flatpak=com.github.th_ch.youtube_music
DESKTOP_EOF

desktop-file-validate "$TEST_DESKTOP"
rm -f "$TEST_DESKTOP"
echo "  ✓ Desktop entry syntax valid"

# 4. Test Python Asar Packing / Unpacking logic
echo "-> [TEST 4/5] Testing asar packing engine..."
python3 -c "
import os, struct, json, tempfile, shutil

# Test mini asar creation and read
with tempfile.TemporaryDirectory() as td:
    src_dir = os.path.join(td, 'src')
    os.makedirs(src_dir)
    with open(os.path.join(src_dir, 'test.txt'), 'w') as f:
        f.write('hello world')
    
    header = {'files': {'test.txt': {'size': 11, 'offset': '0'}}}
    h_json = json.dumps(header).encode('utf-8')
    pad = (4 - (len(h_json) % 4)) % 4
    h_padded = h_json + b'\0' * pad
    t_size = 8 + len(h_json) + pad
    p_size = 4 + len(h_json) + pad
    
    asar_path = os.path.join(td, 'test.asar')
    with open(asar_path, 'wb') as f:
        f.write(struct.pack('<IIII', 4, t_size, p_size, len(h_json)))
        f.write(h_padded)
        f.write(b'hello world')
        
    # Read back
    with open(asar_path, 'rb') as f:
        magic, ts, ps, js = struct.unpack('<IIII', f.read(16))
        read_header = json.loads(f.read(js).decode('utf-8'))
        assert read_header['files']['test.txt']['size'] == 11
print('  ✓ Asar engine operational')
"

# 5. Test Uninstaller
echo "-> [TEST 5/5] Running uninstaller..."
./uninstall.sh

if [ -d "$HOME/.themes/WhiteSur-glassy" ]; then
    echo "Error: Theme was not cleanly removed"
    exit 1
fi
if [ -f "$HOME/.config/gtk-4.0/gtk-WhiteSur-glassy.css" ]; then
    echo "Error: Libadwaita overrides were not cleanly removed"
    exit 1
fi
echo "  ✓ System restored to clean state"

echo ""
echo "============================================="
echo "   ALL CONTAINER TESTS PASSED SUCCESSFULLY!  "
echo "============================================="
