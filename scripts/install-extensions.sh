#!/bin/bash
set -e

echo "=== GNOME Extensions Installer ==="

if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "Error: gnome-extensions CLI tool not found. Are you running GNOME?"
    exit 1
fi

python3 - << 'PYEOF'
import urllib.request, json, subprocess, tempfile, os, sys

EXTENSIONS = [
    {
        "name": "User Themes",
        "uuid": "user-theme@gnome-shell-extensions.gcampax.github.com",
        "url": "https://extensions.gnome.org/extension/19/user-themes/"
    },
    {
        "name": "Blur my Shell",
        "uuid": "blur-my-shell@aunetx",
        "url": "https://extensions.gnome.org/extension/3193/blur-my-shell/"
    },
    {
        "name": "Dash to Dock",
        "uuid": "dash-to-dock@micxgx.gmail.com",
        "url": "https://extensions.gnome.org/extension/307/dash-to-dock/"
    },
    {
        "name": "Logo Menu",
        "uuid": "logomenu@aryan_k",
        "url": "https://extensions.gnome.org/extension/4451/logo-menu/"
    }
]

def get_shell_version():
    try:
        out = subprocess.check_output(["gnome-shell", "--version"]).decode().strip()
        ver_str = out.split()[-1]
        major = ver_str.split(".")[0]
        return major
    except Exception:
        return "47"

def get_installed_list():
    try:
        out = subprocess.check_output(["gnome-extensions", "list"]).decode()
        return out.splitlines()
    except Exception:
        return []

def get_download_url(uuid, target_shell_ver):
    api_url = f"https://extensions.gnome.org/extension-info/?uuid={uuid}"
    req = urllib.request.Request(api_url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read().decode())
    
    version_map = data.get("shell_version_map", {})
    pk = None
    if target_shell_ver in version_map:
        pk = version_map[target_shell_ver]["pk"]
    else:
        valid_versions = [v for v in version_map.keys() if v.replace(".", "").isdigit()]
        if valid_versions:
            sorted_vers = sorted(valid_versions, key=lambda v: float(v))
            pk = version_map[sorted_vers[-1]]["pk"]
    
    if pk:
        return f"https://extensions.gnome.org/download-extension/{uuid}.shell-extension.zip?version_tag={pk}"
    return None

shell_ver = get_shell_version()
print(f"Detected GNOME Shell version: {shell_ver}")
installed = get_installed_list()

for ext in EXTENSIONS:
    name = ext["name"]
    uuid = ext["uuid"]
    print(f"\nChecking {name} ({uuid})...")
    
    if uuid in installed:
        print(f"  [✓] {name} is already installed. Ensuring enabled...")
        subprocess.run(["gnome-extensions", "enable", uuid], check=False)
        continue

    print(f"  -> Fetching package for GNOME Shell {shell_ver}...")
    try:
        dl_url = get_download_url(uuid, shell_ver)
        if not dl_url:
            print(f"  [!] No compatible bundle found for GNOME Shell {shell_ver}.")
            print(f"      Install manually at: {ext['url']}")
            continue

        with tempfile.NamedTemporaryFile(suffix=".zip", delete=False) as tmp_file:
            tmp_path = tmp_file.name

        req = urllib.request.Request(dl_url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
        with urllib.request.urlopen(req, timeout=15) as resp, open(tmp_path, "wb") as out_f:
            out_f.write(resp.read())

        print(f"  -> Installing extension bundle...")
        subprocess.run(["gnome-extensions", "install", "--force", tmp_path], check=True)
        os.remove(tmp_path)

        subprocess.run(["gnome-extensions", "enable", uuid], check=False)
        print(f"  [✓] {name} installed and enabled successfully.")
    except Exception as e:
        print(f"  [!] Failed to install {name} automatically: {e}")
        print(f"      You can install it manually from: {ext['url']}")

print("\nExtensions setup finished. You may need to restart GNOME Shell or log out/in if changes do not appear immediately.")
PYEOF
