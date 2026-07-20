# Fedora 44 + Hyprland — System Setup

Snapshot of the full system state on this PC, captured **2026-07-21**. Use this to verify a rebuild matches the original, or to debug what's different.

## Machine

| Spec | Value |
|---|---|
| OS | Fedora 44 (Forty Four) |
| Kernel | 7.1.3-201.fc44.x86_64 |
| CPU | AMD Ryzen 7 3700X, 8 cores / 16 threads |
| GPU | NVIDIA GA106 **RTX 3060 Lite Hash Rate** |
| NVIDIA driver | **610.43.03** (akmod-nvidia, RPM Fusion nonfree) |
| Audio | AMD Starship/Matisse (analog) + NVIDIA HDMI audio |
| User | `sadman` · groups: `sadman wheel docker` |
| Shell | `/usr/bin/zsh` |

## Package counts

- **2167** packages installed (full list: `fedora-installed-packages.txt`)
- **397** user-installed (`fedora-userinstalled-packages.txt` — closest to "what you chose")
- **112** Nerd Font files (JetBrainsMono: `fonts-installed.txt`)
- **61** enabled system services · **10** enabled user services

## Third-party repositories

Repo config files saved in `repos/`. Key ones:

| Repo | Purpose | Enable command |
|---|---|---|
| **rpmfusion-free** / **rpmfusion-nonfree** | codecs, NVIDIA driver | install release RPMs (see `fedora-install.sh`) |
| **copr:solopasha/hyprland** | Hyprland stack | `dnf copr enable solopasha/hyprland` |
| **copr:scottames/ghostty** | Ghostty terminal | `dnf copr enable scottames/ghostty` |
| **copr:phracek/PyCharm** | PyCharm (disabled) | `dnf copr enable phracek/PyCharm` |
| **docker-ce-stable** | Docker CE | `dnf config-manager add-repo docker-ce.repo` |
| **google-chrome** | Chrome | install chrome-stable RPM |
| **cuda-fedora44** | CUDA toolkit | requires NVIDIA developer auth |
| **remi** | PHP toolchain | enable if doing PHP work |

## Hyprland stack (from solopasha COPR)

```
hyprland-0.51.1      hyprpaper-0.7.6      hypridle-0.1.7       hyprlock-0.9.2
hyprcursor-0.1.13    hyprpicker-0.4.5     hyprpolkitagent-0.1.3  hyprshot-1.3.0
hyprland-qt-support  hyprland-uwsm        xdg-desktop-portal-hyprland-1.3.11
waybar-0.15.0        kitty-0.47.1         ghostty-1.3.1        wofi-1.5.3
nwg-drawer-0.4.9     nwg-panel-0.10.5     swaync (latest)
```

## Audio (PipeWire)

- **PipeWire 1.6.8** + Wireplumber 0.5.14 — full session audio stack
- 3 sinks: `alsa_output.pci-0000_28_00.4.analog-stereo` (default), USB Audio, HDMI
- User services: `pipewire`, `pipewire-pulse`, `wireplumber` all enabled

## NVIDIA driver

- `akmod-nvidia-610.43.03` — builds kernel module per running kernel
- `kmod-nvidia-7.1.3-201.fc44.x86_64-610.43.03` — compiled kmod for current kernel
- Full CUDA stack: `xorg-x11-drv-nvidia-cuda`, `-cuda-libs`, `-power`
- System services: `nvidia-hibernate`, `nvidia-powerd` enabled

**Secure Boot caveat:** akmod-nvidia cannot self-sign without MOK enrollment. If Secure Boot is on, run `sudo mokutil --enroll-key` against the RPM Fusion MOK PEM before reboot.

## Enabled services (highlights)

**System:** NetworkManager, bluetooth, firewalld, docker, akmods, nvidia-powerd, chronyd, sshd, systemd-resolved, auditd, abrt stack.

**User:** pipewire, pipewire-pulse, wireplumber, dbus-broker, obex, xdg-user-dirs, grub-boot-success.timer.

Full lists in `enabled-services-system.txt` and `enabled-services-user.txt`.

## Fonts

- **JetBrainsMono Nerd Font** installed at `~/.local/share/fonts/JetBrainsMono/` (112 variants including Italic, Bold, ExtraLight, etc. — not an RPM install, downloaded from `nerd-fonts` GitHub releases)
- RPM font packages: `jetbrains-mono-fonts-all`

## What this snapshot does NOT include

- `/home/sadman` user data (Documents, Pictures, projects)
- Browser profiles, SSH keys, GPG keys
- Application state in `~/.config/chromium`, `~/.config/Code`, `~/.local/share/`
- Database contents (MariaDB, Docker volumes)
- Any secrets, tokens, or passwords

## Rebuild procedure

1. Install Fedora 44 (Workcraft or Server netinst).
2. `git clone <repo> ~/dotfiles && cd ~/dotfiles`
3. `sudo ./setup-fedora/fedora-install.sh --full`
4. Reboot (NVIDIA akmod + group membership).
5. Verify with `nvidia-smi`, `hyprctl version`, `pgrep -a waybar`.
6. `./stowup` to symlink all dotfile packages.

See `fedora-install.sh` for the full idempotent bootstrap.
