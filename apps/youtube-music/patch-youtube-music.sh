#!/bin/bash
set -e

echo "=== YouTube Music Flatpak Glassy Patcher ==="

FLATPAK_ID="com.github.th_ch.youtube_music"
APP_SYSTEM_DIR="/var/lib/flatpak/app/$FLATPAK_ID/current/active/files"
APP_USER_DIR="$HOME/.local/share/flatpak/app/$FLATPAK_ID/current/active/files"

# 1. Dependency Checks
if ! command -v flatpak >/dev/null 2>&1; then
    echo "Error: Flatpak is not installed on this system."
    echo "Please install flatpak first: https://flatpak.org/setup/"
    exit 1
fi

if [ ! -d "$APP_SYSTEM_DIR" ] && [ ! -d "$APP_USER_DIR" ]; then
    echo "Notice: YouTube Music Flatpak ($FLATPAK_ID) is not installed."
    echo "Note: YouTube Music is not on Flathub (distributed via GitHub Releases as .flatpak)."
    PATCH_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_HELPER="$PATCH_SCRIPT_DIR/../../scripts/install-youtube-music.sh"

    if [ -t 0 ] && [ -f "$INSTALL_HELPER" ]; then
        read -p "Would you like to download and install the latest Flatpak release from GitHub now? [y/N]: " ans_install
        case "$ans_install" in
            [yY]*)
                echo "Downloading and installing YouTube Music Flatpak from GitHub..."
                bash "$INSTALL_HELPER"
                ;;
            *)
                echo "Skipping patch."
                echo "Download the .flatpak bundle from: https://github.com/pear-devs/pear-desktop/releases"
                echo "Install it via: flatpak install YouTube-Music-*-x86_64.flatpak"
                exit 1
                ;;
        esac
    else
        echo "Error: YouTube Music Flatpak ($FLATPAK_ID) is not installed."
        echo "Download the .flatpak bundle from: https://github.com/pear-devs/pear-desktop/releases"
        echo "Install it via: flatpak install YouTube-Music-*-x86_64.flatpak"
        if [ -f "$INSTALL_HELPER" ]; then
            echo "Or run: bash scripts/install-youtube-music.sh"
        fi
        exit 1
    fi
fi

if [ -d "$APP_SYSTEM_DIR" ]; then
    SOURCE_FILES="$APP_SYSTEM_DIR"
elif [ -d "$APP_USER_DIR" ]; then
    SOURCE_FILES="$APP_USER_DIR"
else
    echo "Error: Could not locate installed files for $FLATPAK_ID."
    exit 1
fi

DEST_DIR="$HOME/.local/share/youtube-music-glassy"
mkdir -p "$DEST_DIR/files"
mkdir -p "$DEST_DIR/backup"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$HOME/.local/bin"

# 2. Gracefully stop running instances
echo "Stopping any running instance of YouTube Music..."
flatpak kill "$FLATPAK_ID" 2>/dev/null || true
pkill -f "youtube-music" 2>/dev/null || true
sleep 1

# 3. Backup and update config.json
CONFIG_PATH="$HOME/.var/app/$FLATPAK_ID/config/YouTube Music/config.json"
if [ -f "$CONFIG_PATH" ]; then
    echo "Backing up user config.json..."
    cp -f "$CONFIG_PATH" "$DEST_DIR/backup/config.json.bak"
    python3 -c "
import json
try:
    with open('$CONFIG_PATH', 'r') as f:
        cfg = json.load(f)
    if 'plugins' not in cfg:
        cfg['plugins'] = {}
    cfg['plugins']['transparent-player'] = {
        'enabled': True,
        'opacity': 0.75,
        'type': 'none'
    }
    with open('$CONFIG_PATH', 'w') as f:
        json.dump(cfg, f, indent=4)
    print('Updated config.json: enabled transparent-player plugin.')
except Exception as e:
    print(f'Warning updating config.json: {e}')
"
fi

# 4. Reflink clone base Flatpak files (takes ~0 bytes extra disk space on Btrfs)
echo "Reflink-cloning Flatpak runtime files..."
cp -a --reflink=auto "$SOURCE_FILES"/* "$DEST_DIR/files/"

# 5. Patch app.asar using Python
ORIG_ASAR="$SOURCE_FILES/lib/$FLATPAK_ID/resources/app.asar"
TARGET_ASAR="$DEST_DIR/files/lib/$FLATPAK_ID/resources/app.asar"
TEMP_WORK_DIR=$(mktemp -d -t ytm-patch-XXXXXX)

echo "Patching app.asar with transparency visual hooks..."
python3 - << PYEOF
import os, struct, json, hashlib

work_dir = "$TEMP_WORK_DIR"
orig_asar = "$ORIG_ASAR"
target_asar = "$TARGET_ASAR"

# 1. Unpack asar
with open(orig_asar, 'rb') as f:
    magic, total_size, pickle_size, json_size = struct.unpack('<IIII', f.read(16))
    header = json.loads(f.read(json_size).decode('utf-8'))
    base = 16 + json_size
    padding_len = (4 - (json_size % 4)) % 4
    base += padding_len
    
    def extract_node(node, cur_path):
        if 'files' in node:
            os.makedirs(cur_path, exist_ok=True)
            for name, child in node['files'].items():
                extract_node(child, os.path.join(cur_path, name))
        elif 'offset' in node:
            os.makedirs(os.path.dirname(cur_path), exist_ok=True)
            f.seek(base + int(node['offset']))
            with open(cur_path, 'wb') as out_f:
                out_f.write(f.read(int(node['size'])))

    extract_node(header, work_dir)

# 2. Patch files
index_file = os.path.join(work_dir, 'dist', 'main', 'index.js')
with open(index_file, 'r', encoding='utf-8') as f:
    idx_content = f.read()

# Enable transparency on BrowserWindow
idx_content = idx_content.replace(
    'backgroundColor: "#000",\n\t\tshow: false,',
    'backgroundColor: "#00000000",\n\t\ttransparent: true,\n\t\tshow: false,',
    1
)

# Enable transparent visuals flag
idx_content = idx_content.replace(
    'app.commandLine.appendSwitch("disable-features", "FluentScrollbar");',
    'app.commandLine.appendSwitch("disable-features", "FluentScrollbar");\napp.commandLine.appendSwitch("enable-transparent-visuals");',
    1
)

# Injected CSS
css_addition = (
    ":root{"
    "--ytmusic-color-black1:rgba(20,20,22,0.75)!important;"
    "--ytmusic-color-black2:rgba(26,26,28,0.75)!important;"
    "--ytmusic-color-black3:rgba(32,32,35,0.75)!important;"
    "--ytmusic-color-black4:rgba(38,38,42,0.75)!important;"
    "--ytmusic-background-black:rgba(20,20,22,0.75)!important;"
    "--ytmusic-overlay-background-brand:rgba(20,20,22,0.75)!important;"
    "--ytmd-transparent-player-transparency-color:#141416;"
    "--ytmd-transparent-player-opacity:0.75;"
    "--ytmd-transparent-player-transparent-background:rgba(20,20,22,0.75);"
    "--ytmd-transparent-player-transparent-background-dark:rgba(16,16,18,0.85);"
    "--ytmd-transparent-player-backdrop-blur:blur(20px)}"
    "html,body{"
    "background-color:rgba(20,20,22,0.75)!important;"
    "background:rgba(20,20,22,0.75)!important}"
    "body.transparent-background-color{"
    "background-color:rgba(20,20,22,0.75)!important;"
    "background:rgba(20,20,22,0.75)!important}"
    "ytmusic-app-layout,ytmusic-app{"
    "background:transparent!important;"
    "background-color:transparent!important}"
    "#layout #nav-bar-background,#layout #player-bar-background{"
    "background:rgba(16,16,18,0.75)!important;"
    "backdrop-filter:blur(20px)!important;"
    "-webkit-backdrop-filter:blur(20px)!important}"
    "ytmusic-nav-bar,ytmusic-player-bar{background:transparent!important}"
    "ytmusic-app-layout[player-page-open] #nav-bar-background.ytmusic-app-layout,"
    "ytmusic-app-layout[player-page-open] #player-bar-background.ytmusic-app-layout{opacity:0!important}"
    "#player-page{background:transparent!important}"
    "#mini-guide-background,#guide,#guide #guide-wrapper,ytmusic-guide-renderer,ytmusic-guide-section-renderer{"
    "background:transparent!important;border:none!important}"
    "#browse-page #background{display:none!important}"
    "#browse-page .background-gradient{background:transparent!important}"
    "ytmusic-browse-response,ytmusic-section-list-renderer,#contents.ytmusic-section-list-renderer,"
    "#header.ytmusic-item-section-renderer,ytmusic-item-section-renderer,ytmusic-detail-header-renderer{"
    "background:transparent!important}"
    "#search-page #tabs.stuck{"
    "background:rgba(20,20,22,0.75)!important;"
    "backdrop-filter:blur(20px)!important;"
    "-webkit-backdrop-filter:blur(20px)!important}"
    "ytmusic-menu-popup-renderer,tp-yt-paper-listbox{"
    "background:rgba(28,28,30,0.85)!important;"
    "backdrop-filter:blur(25px)!important;"
    "-webkit-backdrop-filter:blur(25px)!important;"
    "border:1px solid rgba(255,255,255,0.12)!important;"
    "border-radius:12px!important;"
    "box-shadow:0 8px 32px rgba(0,0,0,0.5)!important}"
    "ytmusic-search-box[opened],ytmusic-search-suggestions-section{"
    "background:rgba(28,28,30,0.85)!important;"
    "backdrop-filter:blur(25px)!important;"
    "-webkit-backdrop-filter:blur(25px)!important;"
    "border-radius:12px!important}"
    "nav[data-ytmd-main-panel]{background-color:transparent!important}"
    "#ytmd-title-bar-main-panel{"
    "background:rgba(16,16,18,0.75)!important;"
    "backdrop-filter:blur(20px)!important;"
    "-webkit-backdrop-filter:blur(20px)!important}"
    ".av-toggle.ytmusic-av-toggle{background-color:rgba(35,35,40,0.6)!important;border-radius:8px!important}"
)
target_css_end = 'tp-yt-iron-dropdown,tp-yt-paper-dialog{app-region:no-drag}";'
replacement_css_end = 'tp-yt-iron-dropdown,tp-yt-paper-dialog{app-region:no-drag}' + css_addition + '";'
idx_content = idx_content.replace(target_css_end, replacement_css_end, 1)

with open(index_file, 'w', encoding='utf-8') as f:
    f.write(idx_content)

# Patch transparent-player plugin for Linux
tp_file = os.path.join(work_dir, 'dist', 'main', 'transparent-player-C54mRArg.js')
if os.path.exists(tp_file):
    with open(tp_file, 'r', encoding='utf-8') as f:
        tp_content = f.read()
    tp_content = tp_content.replace('platform: Platform.Windows', 'platform: Platform.Windows | Platform.Linux')
    tp_content = tp_content.replace('enabled: false,\n\topacity: .5', 'enabled: true,\n\topacity: .75')
    tp_content = tp_content.replace('window.setBackgroundColor?.(`rgba(0, 0, 0, ${config.opacity})`);', 'window.setBackgroundColor?.("#00000000");')
    with open(tp_file, 'w', encoding='utf-8') as f:
        f.write(tp_content)

# Patch renderer
renderer_file = os.path.join(work_dir, 'dist', 'renderer', 'youtube-music.iife.js')
if os.path.exists(renderer_file):
    with open(renderer_file, 'r', encoding='utf-8') as f:
        ren_content = f.read()
    ren_content = ren_content.replace('platform:jo.Windows,config:Mo', 'platform:jo.Windows|jo.Linux,config:Mo', 1)
    ren_content = ren_content.replace('let Mo={enabled:!1,opacity:.5,type:Toe.ACRYLIC};', 'let Mo={enabled:!0,opacity:.75,type:Toe.NONE};', 1)
    with open(renderer_file, 'w', encoding='utf-8') as f:
        f.write(ren_content)

# 3. Repack asar
unpacked_set = {
    'assets/error.html',
    'assets/generated/icons/mac/icon.icns',
    'assets/generated/icons/png/1024x1024.png',
    'assets/generated/icons/png/128x128.png',
    'assets/generated/icons/png/16x16.png',
    'assets/generated/icons/png/24x24.png',
    'assets/generated/icons/png/256x256.png',
    'assets/generated/icons/png/32x32.png',
    'assets/generated/icons/png/48x48.png',
    'assets/generated/icons/png/512x512.png',
    'assets/generated/icons/png/64x64.png',
    'assets/generated/icons/win/icon.ico',
    'assets/media-icons-black/next.png',
    'assets/media-icons-black/pause.png',
    'assets/media-icons-black/play.png',
    'assets/media-icons-black/previous.png',
    'assets/youtube-music-tray-paused.png',
    'assets/youtube-music-tray.png',
    'assets/youtube-music.png',
    'assets/youtube-music.svg'
}

def get_integrity(file_path):
    BLOCK_SIZE = 4 * 1024 * 1024
    blocks = []
    hasher = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while True:
            chunk = f.read(BLOCK_SIZE)
            if not chunk: break
            blocks.append(hashlib.sha256(chunk).hexdigest())
            hasher.update(chunk)
    return {'algorithm': 'SHA256', 'hash': hasher.hexdigest(), 'blockSize': BLOCK_SIZE, 'blocks': blocks}

file_list = []
for root, dirs, files in os.walk(work_dir):
    dirs.sort()
    files.sort()
    for f in files:
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, work_dir)
        file_list.append((rel_path, full_path))

new_header = {'files': {}}
current_offset = 0

for rel_path, full_path in file_list:
    parts = rel_path.split(os.sep)
    curr = new_header['files']
    for p in parts[:-1]:
        if p not in curr: curr[p] = {'files': {}}
        curr = curr[p]['files']
    file_name = parts[-1]
    file_size = os.path.getsize(full_path)
    integrity = get_integrity(full_path)
    norm_rel = rel_path.replace('\\', '/')
    if norm_rel in unpacked_set:
        curr[file_name] = {'size': file_size, 'unpacked': True, 'integrity': integrity}
    else:
        curr[file_name] = {'size': file_size, 'offset': str(current_offset), 'integrity': integrity}
        current_offset += file_size

header_json = json.dumps(new_header, separators=(',', ':')).encode('utf-8')
j_size = len(header_json)
pad_len = (4 - (j_size % 4)) % 4
header_json_padded = header_json + b'\0' * pad_len
t_size = 8 + j_size + pad_len
p_size = 4 + j_size + pad_len

header_bytes = struct.pack('<IIII', 4, t_size, p_size, j_size) + header_json_padded

with open(target_asar, 'wb') as out_f:
    out_f.write(header_bytes)
    for rel_path, full_path in file_list:
        norm_rel = rel_path.replace('\\', '/')
        if norm_rel not in unpacked_set:
            with open(full_path, 'rb') as in_f:
                while True:
                    buf = in_f.read(1024 * 1024)
                    if not buf: break
                    out_f.write(buf)

print(f"Patched asar packed successfully: {os.path.getsize(target_asar)} bytes.")
PYEOF

rm -rf "$TEMP_WORK_DIR"

# 6. Create desktop launcher in ~/.local/share/applications
echo "Creating application launcher..."
cat << DESKTOP_EOF > "$HOME/.local/share/applications/com.github.th_ch.youtube_music.desktop"
[Desktop Entry]
Name=YouTube Music
Exec=/usr/bin/flatpak run --branch=master --arch=x86_64 --app-path=$DEST_DIR/files --command=electron-wrapper --file-forwarding $FLATPAK_ID @@u %U @@
Terminal=false
Type=Application
Icon=$FLATPAK_ID
StartupWMClass=$FLATPAK_ID
Comment=YouTube Music Desktop App with glassy transparent blur
Categories=AudioVideo;
X-Flatpak=$FLATPAK_ID
DESKTOP_EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# 7. Create CLI wrapper in ~/.local/bin
cat << BIN_EOF > "$HOME/.local/bin/youtube-music"
#!/bin/bash
exec /usr/bin/flatpak run --branch=master --arch=x86_64 --app-path=$DEST_DIR/files --command=electron-wrapper --file-forwarding $FLATPAK_ID "\$@"
BIN_EOF
chmod +x "$HOME/.local/bin/youtube-music"

echo "=== YouTube Music glassy patch complete! ==="
