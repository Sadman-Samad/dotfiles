#!/usr/bin/env bash
# fedora-install.sh — Reproduce this PC's Fedora 44 + Hyprland setup from scratch.
#
# Captured: 2026-07-21
# Target:   Fedora 44 (x86_64), AMD Ryzen 7 3700X, NVIDIA RTX 3060 (driver 610.x)
#
# Usage:
#   sudo ./fedora-install.sh           # install packages + repos
#   sudo ./fedora-install.sh --full    # also enable services, groups, stow configs
#
# This script is idempotent: re-running it will only install what's missing.
# Pair with stow for dotfiles:  ./stowup hyprland waybar kitty ...

set -euo pipefail

# ---- colors ----
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR]${NC} $*" >&2; }

FULL=0
[[ "${1:-}" == "--full" ]] && FULL=1

if [[ $EUID -ne 0 ]]; then
    error "Run with sudo: sudo $0 $*"
    exit 1
fi

# ============================================================
# 1. Third-party repositories (RPM Fusion + COPRs + extras)
# ============================================================
info "Configuring third-party repositories..."

# RPM Fusion (free + nonfree) — required for NVIDIA driver, multimedia codecs
if ! dnf repolist | grep -q "^rpmfusion-free "; then
    dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    success "RPM Fusion installed"
else
    success "RPM Fusion already configured"
fi

# COPR: solopasha/hyprland — Hyprland stack for Fedora
if ! dnf repolist | grep -q "solopasha/hyprland"; then
    dnf copr enable -y solopasha/hyprland
    success "Hyprland COPR enabled"
else
    success "Hyprland COPR already enabled"
fi

# COPR: scottames/ghostty — Ghostty terminal
if ! dnf repolist | grep -q "scottames/ghostty"; then
    dnf copr enable -y scottames/ghostty
    success "Ghostty COPR enabled"
else
    success "Ghostty COPR already enabled"
fi

# Other repos present on source machine (install if missing, skip if gated behind auth)
# - google-chrome, docker-ce, cuda-fedora44, remi, gcloud — enable on demand
if ! dnf repolist | grep -q "^google-chrome "; then
    if [[ ! -f /etc/yum.repos.d/google-chrome.repo ]]; then
        dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm && \
            success "Google Chrome repo added" || warn "Google Chrome repo skipped"
    fi
fi

if ! dnf repolist | grep -q "^docker-ce-stable"; then
    dnf config-manager add-repo \
        https://download.docker.com/linux/fedora/docker-ce.repo && \
        success "Docker CE repo added" || warn "Docker CE repo skipped"
fi

# ============================================================
# 2. Core system packages
# ============================================================
info "Installing core system packages..."

CORE_PKGS=(
    # --- Hyprland compositor + ecosystem (from solopasha COPR) ---
    hyprland hyprland-qt-support hyprland-uwsm
    hyprpaper hypridle hyprlock hyprcursor hyprpicker hyprpolkitagent hyprshot
    xdg-desktop-portal-hyprland
    # --- Status bar + launchers ---
    waybar wofi nwg-drawer nwg-panel
    # --- Terminals ---
    kitty ghostty
    # --- Audio (PipeWire stack) ---
    pipewire pipewire-alsa pipewire-pulseaudio pipewire-utils pipewire-gstreamer
    pipewire-jack-audio-connection-kit pipewire-plugin-libcamera
    wireplumber pavucontrol
    # --- Notifications ---
    swaync
    # --- Fonts ---
    jetbrains-mono-fonts-all
    # --- Shell + multiplexer ---
    zsh tmux
    # --- Editors ---
    neovim
    # --- Screenshot / utility ---
    grim slurp wl-clipboard brightnessctl playerctl
    # --- Network / bluetooth ---
    NetworkManager-wifi bluez bluez-tools
    # --- Base desktop utilities ---
    polkit-gnome xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
    # --- Archive / file managers ---
    nautilus file-roller
    # --- Browsers ---
    google-chrome-stable
    # --- Dev tooling ---
    git git-lfs curl wget unzip rsync ripgrep fzf htop btop
    python3 python3-pip nodejs npm go gcc clang make docker-ce docker-ce-cli containerd.io
)

dnf install -y "${CORE_PKGS[@]}"
success "Core packages installed (${#CORE_PKGS[@]} packages)"

# ============================================================
# 3. NVIDIA proprietary driver (RPM Fusion nonfree)
# ============================================================
info "Installing NVIDIA driver (RTX 3060)..."

NVIDIA_PKGS=(
    akmod-nvidia
    xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-cuda
    xorg-x11-drv-nvidia-cuda-libs xorg-x11-drv-nvidia-power
    nvidia-settings nvidia-persistenced
)

dnf install -y "${NVIDIA_PKGS[@]}"
success "NVIDIA driver installed (will build kernel module on next boot via akmod)"

# ============================================================
# 4. Full package list (optional — reproduce everything)
# ============================================================
if [[ -f "$(dirname "$0")/setup-fedora/fedora-userinstalled-packages.txt" ]]; then
    info "Installing full user-installed package list ($(wc -l < "$(dirname "$0")/setup-fedora/fedora-userinstalled-packages.txt") packages)..."
    xargs -a "$(dirname "$0")/setup-fedora/fedora-userinstalled-packages.txt" dnf install -y || \
        warn "Some optional packages failed to install (expected for copr/cuda-specific ones)"
    success "Full package list processed"
fi

# ============================================================
# 5. --full: services, groups, shell, configs
# ============================================================
if [[ $FULL -eq 1 ]]; then
    info "Enabling system services..."

    SYSTEM_SERVICES=(
        NetworkManager NetworkManager-dispatcher bluetooth firewalld
        docker nvidia-powerd nvidia-persistenced akmods chronyd
    )
    for svc in "${SYSTEM_SERVICES[@]}"; do
        systemctl enable --now "$svc" 2>/dev/null && success "$svc enabled" || warn "$svc skipped"
    done

    USER_SERVICES=(
        pipewire pipewire-pulse wireplumber dbus-broker
    )
    for svc in "${USER_SERVICES[@]}"; do
        sudo -u "${SUDO_USER:-sadman}" systemctl --user enable --now "$svc" 2>/dev/null \
            && success "user/$svc enabled" || warn "user/$svc skipped"
    done

    # --- User groups ---
    info "Configuring user groups..."
    for grp in wheel docker; do
        usermod -aG "$grp" "${SUDO_USER:-sadman}" && success "$SUDO_USER added to $grp"
    done

    # --- Default shell ---
    info "Setting default shell to zsh..."
    chsh -s /usr/bin/zsh "${SUDO_USER:-sadman}" 2>/dev/null && success "Shell set" || warn "chsh failed (run manually)"

    # --- Fonts: install Nerd Fonts locally for the user ---
    if [[ -d "/home/${SUDO_USER:-sadman}/.local/share/fonts/JetBrainsMono" ]]; then
        info "Nerd Fonts already present in ~/.local/share/fonts/JetBrainsMono"
    else
        info "Installing JetBrainsMono Nerd Font..."
        mkdir -p "/home/${SUDO_USER:-sadman}/.local/share/fonts"
        TMP=$(mktemp -d)
        curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o "$TMP/jbmono.zip"
        unzip -q "$TMP/jbmono.zip" -d "/home${SUDO_USER:+/}/$SUDO_USER/.local/share/fonts/JetBrainsMono"
        chown -R "$SUDO_USER:" "/home/${SUDO_USER:-sadman}/.local/share/fonts/JetBrainsMono"
        rm -rf "$TMP"
        success "JetBrainsMono Nerd Font installed"
    fi

    # --- Stow dotfiles ---
    info "Stowing dotfile packages..."
    cd "$(dirname "$0")"
    for pkg in hyprland waybar kitty ghostty nvim tmux zsh swaync wofi bin p10k gtk; do
        sudo -u "${SUDO_USER:-sadman}" stow -D "$pkg" 2>/dev/null
        sudo -u "${SUDO_USER:-sadman}" stow "$pkg" 2>/dev/null && success "stowed $pkg" || warn "stow $pkg skipped"
    done
fi

# ============================================================
# 6. Final notes
# ============================================================
cat << 'EOF'

============================================================
 Fedora + Hyprland setup complete.
============================================================

Next steps:
  1. REBOOT — required for:
     - NVIDIA akmod kernel module to build & load
     - wheel/docker group membership to take effect
     - PipeWire services to start in new session

  2. After reboot, verify:
     nvidia-smi                              # should show RTX 3060
     hyprctl version                         # Hyprland compositor
     pgrep -a waybar                         # status bar running

  3. Dotfiles:
     cd ~/dotfiles && ./stowup               # symlinks all configs

  4. Audio:
     wpctl status                            # PipeWire sinks
     pactl set-default-sink <name>           # if wrong device selected

Manual review (script intentionally skips):
  - /etc/yum.repos.d/cuda-fedora44.repo      # needs NVIDIA developer auth
  - /etc/yum.repos.d/remi*.repo              # PHP-specific, enable if needed
  - Secure Boot: akmod-nvidia won't sign keys without MOK enrollment

EOF

success "Setup script finished."
