---
name: docker-testing
description: >-
  Use this skill whenever testing install.sh, uninstall.sh, theme setup scripts,
  Flatpak overrides, or shell/terminal configurations in the WhiteSur-Glassy repository.
  Enforces running all verification inside disposable Docker containers and prohibits
  running installation or modification scripts directly on the user's host machine.
---

# Docker-Based Testing for WhiteSur-Glassy

## Strict Rule: Never Run Scripts on the Host

**NEVER** execute `./install.sh`, `./uninstall.sh`, `theme/libadwaita/setup-libadwaita.sh`, or any script under `scripts/` directly on the user's host machine. These scripts modify `$HOME/.themes`, `$HOME/.config/gtk-4.0`, `$HOME/.bashrc`, `dconf`, `gsettings`, and Flatpak overrides.

All script execution and verification **must** take place inside ephemeral OCI containers (`podman run --rm ...` or `docker run --rm ...`) with the repository mounted read-only (`-v /home/malik/git/WhiteSur-Glassy:/workspace:ro`).

> [!NOTE]
> On this Fedora system, rootless `podman` is available without `sudo` (whereas `/var/run/docker.sock` requires root). Because the Antigravity command sandbox isolates `/run/user`, invoke `podman` with `BypassSandbox: true` and `--security-opt label=disable` (so SELinux labels on the host repository are not altered). Keep all non-container file edits and git checks inside the sandbox (`BypassSandbox: false`).

## Standard Container Test Procedure

### 1. Run the Automated Container Verification Suite

Run the bundled verification script [verify-in-container.sh](./scripts/verify-in-container.sh) inside a disposable Fedora container with the repository mounted read-only:

```bash
podman run --rm --security-opt label=disable -v /home/malik/git/WhiteSur-Glassy:/workspace:ro fedora:latest bash /workspace/.agents/skills/docker-testing/scripts/verify-in-container.sh
```

Or run ad-hoc checks manually:

```bash
podman run --rm --security-opt label=disable -v /home/malik/git/WhiteSur-Glassy:/workspace:ro fedora:latest bash -exc '
  dnf install -y flatpak glib2 dconf python3 git >/dev/null
  # Run tests inside container...
'
```

*(Tip: If an image with dependencies is needed repeatedly during a session, you can tag a temporary local image `whitesur-glassy-test:local` and remove it when done, or run `fedora:latest` / `ubuntu:latest` with `--rm`.)*

### 2. What to Verify in Container Tests

1. **Dependency Check (`--check` and `--help`)**:
   ```bash
   /workspace/install.sh --help
   /workspace/install.sh --check
   ```

2. **Theme & Libadwaita Installation (`--theme`)**:
   ```bash
   /workspace/install.sh --theme < /dev/null
   ```
   - Verify theme files exist in **both** `$HOME/.themes/WhiteSur-glassy` and `${XDG_DATA_HOME:-$HOME/.local/share}/themes/WhiteSur-glassy`.
   - Verify `$HOME/.config/gtk-4.0/gtk.css` and `$HOME/.config/gtk-4.0/gtk-dark.css` are **relative** symlinks (`readlink` equals `gtk-WhiteSur-glassy.css`, not an absolute `/root/...` or `/home/...` path).
   - Verify `$HOME/.config/gtk-4.0/windows-assets` and `$HOME/.config/gtk-4.0/gtk-WhiteSur-Dark.css` exist.

3. **Flatpak Sandbox Simulation**:
   - Check that `~/.local/share/flatpak/overrides/global` (or `flatpak override --user --show`) includes:
     - `xdg-config/gtk-4.0:ro`
     - `xdg-config/gtk-3.0:ro`
     - `xdg-data/themes:ro`
     - `~/.themes:ro`
     - `xdg-data/icons:ro`
     - `~/.icons:ro`
     - `GTK_THEME=WhiteSur-glassy`
   - Simulate Flatpak's `xdg-config/gtk-4.0` bind mount by moving `$HOME/.config/gtk-4.0` to `/tmp/flatpak-app-config/gtk-4.0` (so `$HOME/.config/gtk-4.0` no longer exists at its original path) and confirming that `/tmp/flatpak-app-config/gtk-4.0/gtk.css` and `gtk-dark.css` still resolve cleanly and are readable.

4. **Uninstallation & Backup Restoration (`uninstall.sh`)**:
   - Create dummy pre-existing files (e.g. `~/.config/gtk-4.0/gtk.css` before running `install.sh`) to verify backup creation (`gtk.css.bak`) and restoration on `uninstall.sh`.
   - Run `/workspace/uninstall.sh < /dev/null`.
   - Verify `$HOME/.themes/WhiteSur-glassy` and `$HOME/.local/share/themes/WhiteSur-glassy` are removed.
   - Verify Flatpak overrides in `~/.local/share/flatpak/overrides/global` have removed the theme filesystem/env entries.
