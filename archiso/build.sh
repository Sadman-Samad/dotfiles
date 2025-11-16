#!/bin/bash
#
# Custom Arch Linux ISO Builder
# Build a custom Arch Linux ISO with your dotfiles
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR"

# Use the user's home directory, not root's
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    WORK_DIR="${WORK_DIR:-$USER_HOME/.cache/archiso-work}"
    OUT_DIR="${OUT_DIR:-$USER_HOME/arch-isos}"
else
    WORK_DIR="${WORK_DIR:-$HOME/.cache/archiso-work}"
    OUT_DIR="${OUT_DIR:-$HOME/arch-isos}"
fi

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║         Custom Arch Linux ISO Builder                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
info "Build Configuration:"
echo "  Profile directory: $PROFILE_DIR"
echo "  Work directory:    $WORK_DIR"
echo "  Output directory:  $OUT_DIR"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (or with sudo)"
fi

# Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    error "archiso is not installed. Install it with: sudo pacman -S archiso"
fi

# Confirm build
read -p "Do you want to continue with the build? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    error "Build cancelled by user."
fi

# Clean previous work directory if it exists
if [ -d "$WORK_DIR" ]; then
    info "Cleaning previous work directory..."
    rm -rf "$WORK_DIR"
fi

# Create output directory if it doesn't exist
mkdir -p "$OUT_DIR"

# Build the ISO
info "Starting ISO build... (this will take 15-30 minutes)"
info "Building from profile: $PROFILE_DIR"

mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

if [ $? -eq 0 ]; then
    # Fix ownership if running with sudo
    if [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$OUT_DIR"
    fi

    success "ISO build completed successfully!"
    echo ""
    info "ISO location:"
    ls -lh "$OUT_DIR"/*.iso
    echo ""
    info "You can now:"
    echo "  1. Write to USB: sudo dd if=$OUT_DIR/custom-arch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
    echo "  2. Test in VM: run_archiso -i $OUT_DIR/custom-arch-*.iso"
    echo "  3. Test in QEMU: qemu-system-x86_64 -enable-kvm -m 4G -boot d -cdrom $OUT_DIR/custom-arch-*.iso"
else
    error "ISO build failed! Check the output above for errors."
fi

# Clean work directory
read -p "Do you want to clean the work directory? (yes/no): " CLEAN
if [ "$CLEAN" = "yes" ]; then
    info "Cleaning work directory..."
    rm -rf "$WORK_DIR"
    success "Work directory cleaned!"
fi
