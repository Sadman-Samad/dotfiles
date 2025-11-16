#!/bin/bash
#
# Install yay and AUR packages for Galib OS
# This script runs during the installation process
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

info "Installing yay AUR helper..."

# Install git and base-devel if not already installed
pacman -S --needed --noconfirm git base-devel

# Create build directory
mkdir -p /tmp/yay-build
cd /tmp/yay-build

# Clone yay from AUR
info "Cloning yay from AUR..."
git clone https://aur.archlinux.org/yay.git

# Build and install yay
cd yay
info "Building yay..."
makepkg -si --noconfirm

success "yay installed successfully!"

# Clean up
cd / && rm -rf /tmp/yay-build

# List of AUR packages to install
AUR_PACKAGES=(
    "plymouth-plugin-script"
    "plymouth-theme-spinner"
    "neofetch"
    "ags"
    "swaylock-effects"
    "zen-browser-bin"
    "claude-code"
)

info "Installing AUR packages..."

# Install each AUR package
for package in "${AUR_PACKAGES[@]}"; do
    info "Installing $package..."
    yay -S --noconfirm "$package" || warning "Failed to install $package, continuing..."
done

success "All AUR packages installation complete!"

# Also install any missing packages from your dotfiles that might be useful
info "Installing additional utilities..."

# These might be useful for your dotfiles
yay -S --noconfirm \
    tokei \
    hyperfine \
    procs \
    bottom \
    delta \
    zellij \
    yazi \
    2>/dev/null || echo "Some packages failed, continuing..."

success "Additional utilities installation complete!"
success "AUR package installation finished successfully!"