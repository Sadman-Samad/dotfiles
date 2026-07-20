# Hyprland (Fedora 44)

Custom Catppuccin Mocha Hyprland setup. Adapted from the `omarchy` Arch branch,
rewritten to be self-contained (no Omarchy framework dependency).

## Packages (Fedora)

Enable COPR and install the stack:

```bash
sudo dnf5 copr enable solopasha/hyprland
sudo dnf5 install -y \
  hyprland hyprpaper hypridle hyprlock hyprcursor hyprpicker hyprshot \
  hyprpolkitagent xdg-desktop-portal-hyprland \
  kitty wofi waybar swaync swaybg swaylock swayidle \
  cliphist brightnessctl pamixer btop numlockx network-manager-applet \
  sddm sddm-themes
```

## ⚠️ Fedora 44 aquamarine rebuild

`solopasha/hyprland` COPR's `aquamarine-0.9.5` is built against
`libdisplay-info.so.2`, but Fedora 44 ships `.so.3`. You must rebuild
aquamarine from source as an RPM before hyprland will install.

```bash
# deps
sudo dnf5 install -y meson cmake gcc-c++ rpm-build rpmdevtools \
  libseat-devel libinput-devel wayland-devel wayland-protocols-devel \
  hyprutils-devel pixman-devel libdrm-devel mesa-libgbm-devel \
  systemd-devel libdisplay-info-devel hyprwayland-scanner-devel \
  libglvnd-devel

# hwdata has no .pc file on Fedora — create a stub
sudo tee /usr/share/pkgconfig/hwdata.pc >/dev/null << 'EOF'
prefix=/usr
datarootdir=${prefix}/share
hwdatadir=${datarootdir}/hwdata
Name: hwdata
Description: Hardware identification and configuration data
Version: 0.409
EOF

# build (spec is in this repo at hyprland/aquamarine.spec)
curl -L https://github.com/hyprwm/aquamarine/archive/refs/tags/v0.9.5.tar.gz \
  -o ~/rpmbuild/SOURCES/aquamarine-0.9.5.tar.gz
rpmbuild -bb hyprland/aquamarine.spec
sudo dnf5 install -y ~/rpmbuild/RPMS/x86_64/aquamarine-*.rpm
```

## Display manager

GNOME's GDM was replaced with SDDM:

```bash
sudo systemctl disable gdm
sudo systemctl enable sddm
```

## Catppuccin cursors

```bash
mkdir -p ~/.local/share/icons
cd /tmp
curl -L https://github.com/catppuccin/cursors/releases/latest/download/Catppuccin-Mocha-Dark-Cursors.zip -o cat.zip
unzip -o cat.zip -d ~/.local/share/icons/
```

## NVIDIA

`nvidia_drm.modeset=Y` must be set (already default on this system).
The env vars needed for Hyprland on NVIDIA are in `envs.conf`.

## Keybindings

| Key | Action |
|---|---|
| `Super+Enter` | Kitty terminal |
| `Super+D` / `Super+Space` | Wofi launcher |
| `Super+Q` | Close window |
| `Super+1..0` | Workspaces |
| `Super+H/J/K/L` | Focus (Vim-style) |
| `Super+F` | Float toggle |
| `Super+Shift+E` | Session menu |
| `Super+Shift+R` | Reload config |

## Install configs (via GNU Stow)

```bash
cd ~/dotfiles
stow hyprland waybar kitty wofi swaync gtk bin
```
