#!/bin/bash
# Quick ISO Testing Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Find the ISO
ISO_FILE=$(ls ~/arch-isos/custom-arch-*.iso 2>/dev/null | head -1)
[ -z "$ISO_FILE" ] && error "No ISO found in ~/arch-isos/"

info "Found ISO: $ISO_FILE"
echo ""
echo "1) Live environment only (quick test)"
echo "2) Full test with virtual disk (test installation)"
echo ""
read -p "Choice (1-2): " CHOICE

case $CHOICE in
    1)
        info "Starting QEMU (Ctrl+Alt+G to release mouse)..."
        sleep 1
        qemu-system-x86_64 -enable-kvm -m 4G -cpu host -smp 4 \
            -cdrom "$ISO_FILE" -vga virtio -boot d
        ;;
    2)
        DISK="$HOME/test-arch.qcow2"
        [ ! -f "$DISK" ] && qemu-img create -f qcow2 "$DISK" 40G
        info "Starting QEMU with disk (Ctrl+Alt+G to release mouse)..."
        sleep 1
        qemu-system-x86_64 -enable-kvm -m 4G -cpu host -smp 4 \
            -cdrom "$ISO_FILE" -drive file="$DISK",format=qcow2,if=virtio \
            -vga virtio -boot d -nic user,model=virtio-net-pci
        ;;
    *) error "Invalid choice" ;;
esac
