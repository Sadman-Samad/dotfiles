# Quick Start Guide - Custom Arch Linux ISO

## Build the ISO

```bash
cd ~/dotfiles/archiso
sudo ./build.sh
```

**Build time**: 15-30 minutes
**ISO size**: ~2-4 GB
**Output location**: `~/arch-isos/`

## Test the ISO

```bash
# Quick test in QEMU
qemu-system-x86_64 -enable-kvm -m 4G -boot d -cdrom ~/arch-isos/custom-arch-*.iso
```

## Write to USB

```bash
# Find your USB drive
lsblk

# Write ISO (replace /dev/sdX with your USB drive)
sudo dd if=~/arch-isos/custom-arch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Boot from ISO

After booting, you'll see a welcome menu:

1. **KDE Plasma (Live)** - Test KDE desktop with your dotfiles
2. **Hyprland (Live)** - Test Hyprland with your dotfiles
3. **Install to Disk** - Automated installation
4. **Manual Install** - Advanced users
5. **Shell** - Command line

## Automated Installation

Choose option 3 and follow prompts:
- Select disk (e.g., /dev/sda)
- Enter hostname
- Enter username and password
- Choose desktop environment
- Installation completes in ~15-30 minutes
- System automatically reboots

## After Installation

1. Log in with your username
2. Run: `cd ~/dotfiles && ./install.sh`
3. Enjoy your configured system!

## Troubleshooting

**ISO won't boot**: Verify UEFI mode is enabled in BIOS
**Build fails**: Check you have 10GB+ free space
**Package errors**: Review packages.x86_64 for invalid packages

For detailed documentation, see `README.md`
