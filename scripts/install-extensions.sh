#!/bin/bash
set -e

if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "gnome-extensions CLI tool not found."
    echo "Install it with your package manager (e.g. sudo dnf install gnome-shell or sudo apt install gnome-shell)"
    exit 1
fi

python3 - << 'PYEOF'
import urllib.request, json, subprocess, tempfile, os, sys, ast

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

def run_cmd(cmd):
    try:
        return subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
    except Exception:
        return None

def get_shell_version():
    try:
        out = subprocess.check_output(["gnome-shell", "--version"]).decode().strip()
        ver_str = out.split()[-1]
        major = ver_str.split(".")[0]
        return major
    except Exception:
        return "47"

def get_installed_list():
    installed = set()
    try:
        out = subprocess.check_output(["gnome-extensions", "list"]).decode()
        for line in out.splitlines():
            line = line.strip()
            if line:
                installed.add(line)
    except Exception:
        pass

    user_ext_dir = os.path.expanduser("~/.local/share/gnome-shell/extensions")
    if os.path.isdir(user_ext_dir):
        for entry in os.listdir(user_ext_dir):
            if os.path.isdir(os.path.join(user_ext_dir, entry)):
                installed.add(entry)

    return installed

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

def get_gsettings_list(key):
    try:
        res = run_cmd(["gsettings", "get", "org.gnome.shell", key])
        if res and res.returncode == 0:
            val = res.stdout.strip()
            if val.startswith("["):
                return ast.literal_eval(val)
    except Exception:
        pass
    try:
        res = run_cmd(["dconf", "read", f"/org/gnome/shell/{key}"])
        if res and res.returncode == 0:
            val = res.stdout.strip()
            if val.startswith("["):
                return ast.literal_eval(val)
    except Exception:
        pass
    return []

def set_gsettings_list(key, items):
    formatted = "[" + ", ".join(f"'{x}'" for x in items) + "]"
    run_cmd(["gsettings", "set", "org.gnome.shell", key, formatted])
    run_cmd(["dconf", "write", f"/org/gnome/shell/{key}", formatted])

# Make sure user extensions are enabled globally
run_cmd(["gsettings", "set", "org.gnome.shell", "disable-user-extensions", "false"])
run_cmd(["dconf", "write", "/org/gnome/shell/disable-user-extensions", "false"])

shell_ver = get_shell_version()
installed = get_installed_list()
installed_or_present_uuids = []

for ext in EXTENSIONS:
    name = ext["name"]
    uuid = ext["uuid"]

    if uuid in installed:
        print(f"{name} is already installed.")
    else:
        print(f"Downloading {name}...")
        try:
            dl_url = get_download_url(uuid, shell_ver)
            if not dl_url:
                print(f"Could not find download for GNOME Shell {shell_ver}. You can install manually at: {ext['url']}")
                continue

            with tempfile.NamedTemporaryFile(suffix=".zip", delete=False) as tmp_file:
                tmp_path = tmp_file.name

            req = urllib.request.Request(dl_url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
            with urllib.request.urlopen(req, timeout=15) as resp, open(tmp_path, "wb") as out_f:
                out_f.write(resp.read())

            run_cmd(["gnome-extensions", "install", "--force", tmp_path])
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            print(f"Installed {name}.")
        except Exception as e:
            print(f"Could not download {name}: {e}")
            continue

    schemas_dir = os.path.expanduser(f"~/.local/share/gnome-shell/extensions/{uuid}/schemas")
    if os.path.isdir(schemas_dir):
        run_cmd(["glib-compile-schemas", schemas_dir])

    run_cmd(["gnome-extensions", "enable", uuid])
    installed_or_present_uuids.append(uuid)

# Enable them in settings
if installed_or_present_uuids:
    current_enabled = get_gsettings_list("enabled-extensions")
    updated_enabled = list(dict.fromkeys(current_enabled + installed_or_present_uuids))
    set_gsettings_list("enabled-extensions", updated_enabled)

    current_disabled = get_gsettings_list("disabled-extensions")
    updated_disabled = [u for u in current_disabled if u not in installed_or_present_uuids]
    if len(updated_disabled) != len(current_disabled):
        set_gsettings_list("disabled-extensions", updated_disabled)

    if "user-theme@gnome-shell-extensions.gcampax.github.com" in installed_or_present_uuids:
        theme_name = os.environ.get("WHITESUR_THEME_NAME", "WhiteSur-Glassy-Transparent")
        run_cmd(["dconf", "write", "/org/gnome/shell/extensions/user-theme/name", f"'{theme_name}'"])

print("Extensions configured and enabled.")
PYEOF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/install-rounded-blur.sh" ]; then
    bash "$SCRIPT_DIR/install-rounded-blur.sh" || true
fi
