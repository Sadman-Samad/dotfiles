# Custom Arch Linux ISO with Dotfiles

This directory contains everything needed to build a custom Arch Linux ISO that includes your dotfiles and provides both a live environment and automated installation.

## Features

- **Live Environment**: Boot into KDE Plasma or Hyprland with your dotfiles pre-configured
- **Automated Installation**: One-click installer that sets up Arch Linux with your configurations
- **Hybrid Approach**: ~2-4GB ISO with essential packages pre-installed
- **Pre-configured Desktop**: Choose between KDE Plasma and Hyprland (or both)
- **Dotfiles Included**: Your entire dotfiles repository is bundled in the ISO

## Quick Start

### Building the ISO

```bash
# Navigate to the archiso directory
cd ~/dotfiles/archiso

# Build the ISO (requires root)
sudo ./build.sh
```

The ISO will be created in `~/arch-isos/` by default.

### Testing the ISO

**Option 1: QEMU/KVM (Recommended for testing)**
```bash
# Basic test
qemu-system-x86_64 -enable-kvm -m 4G -boot d -cdrom ~/arch-isos/custom-arch-*.iso

# Full featured test
qemu-system-x86_64 -enable-kvm -m 4G -cpu host -smp 4 \
  -boot d -cdrom ~/arch-isos/custom-arch-*.iso \
  -drive file=test-disk.qcow2,format=qcow2,if=virtio
```

**Option 2: Using archiso helper**
```bash
run_archiso -i ~/arch-isos/custom-arch-*.iso
```

**Option 3: VirtualBox**
1. Create new VM with at least 4GB RAM
2. Attach the ISO as optical drive
3. Enable EFI mode
4. Boot and test

### Writing to USB Drive

**Warning: This will erase all data on the target USB drive!**

```bash
# Identify your USB drive (e.g., /dev/sdb)
lsblk

# Write ISO to USB (replace /dev/sdX with your USB drive)
sudo dd if=~/arch-isos/custom-arch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Or use a GUI tool like balenaEtcher, Ventoy, or GNOME Disks
```

## Directory Structure

```
archiso/
├── airootfs/              # Files to be copied to the live system
│   ├── etc/               # System configuration files
│   └── root/              # Root user home directory
│       ├── dotfiles/      # Your dotfiles repository (copied during build)
│       ├── install-arch.sh  # Automated installer script
│       └── welcome.sh     # Welcome menu shown on boot
├── efiboot/               # EFI boot configuration
├── grub/                  # GRUB boot configuration
├── syslinux/              # SYSLINUX boot configuration
├── packages.x86_64        # List of packages to include in ISO
├── pacman.conf            # Pacman configuration for the build
├── profiledef.sh          # ISO metadata and settings
├── build.sh               # Build script (run this to create ISO)
└── README.md              # This file
```

## Using the Live Environment

When you boot from the ISO, you'll see a welcome menu with these options:

1. **Start KDE Plasma Desktop Environment (Live)**
   - Boot into a full KDE Plasma desktop with your dotfiles
   - Test your configurations before installing
   - Includes all your custom settings and themes

2. **Start Hyprland (Live)**
   - Boot into Hyprland window manager
   - Wayland-based tiling environment
   - Your Hyprland configuration pre-applied

3. **Install Arch Linux to Disk (Automated Installer)**
   - Runs the automated installation script
   - Prompts for disk, hostname, username, password
   - Choose which desktop environment to install
   - Automatically deploys your dotfiles
   - Installs GRUB bootloader
   - Complete installation in ~15-30 minutes

4. **Manual Installation**
   - Shows installation guide
   - For advanced users who want full control
   - Your dotfiles available at `/root/dotfiles`

5. **Shell**
   - Drop to command line
   - Full access to all tools and utilities

## Automated Installation Process

The automated installer (`install-arch.sh`) performs these steps:

1. **Disk Selection**: Choose the target disk
2. **System Configuration**: Set hostname, username, password
3. **Desktop Choice**: Select KDE, Hyprland, or both
4. **Partitioning**: Automatic partitioning (EFI + Swap + Root)
5. **Base Installation**: Install base system and kernel
6. **Configuration**: Set timezone, locale, hostname
7. **User Creation**: Create user with sudo access
8. **Desktop Installation**: Install selected desktop environment
9. **Bootloader**: Install and configure GRUB
10. **Dotfiles**: Copy and prepare dotfiles for deployment
11. **Reboot**: Automatic reboot into new system

### Partition Scheme

The installer creates:
- **EFI partition**: 512MB (FAT32)
- **Swap partition**: 8GB
- **Root partition**: Remaining space (ext4)

## Customization

### Adding/Removing Packages

Edit `packages.x86_64` to customize which packages are included:

```bash
nvim packages.x86_64

# Add your package names (one per line)
# Remove packages you don't need
# Rebuild ISO after changes
```

### Modifying the Installer

The automated installer is located at:
```
airootfs/root/install-arch.sh
```

You can modify:
- Partition sizes
- Default timezone
- Locale settings
- Additional post-install commands

### Changing ISO Metadata

Edit `profiledef.sh` to change:
- ISO name
- ISO label
- Publisher information
- Version string

### Pre-configuring the Live Environment

Add files to `airootfs/` that will be copied to the live system:

```bash
# Example: Add a custom systemd service
mkdir -p airootfs/etc/systemd/system/
cp my-service.service airootfs/etc/systemd/system/

# Example: Add custom MOTD
echo "Welcome to my custom Arch ISO!" > airootfs/etc/motd
```

## Updating Dotfiles in ISO

The ISO includes a snapshot of your dotfiles. To update:

1. Make changes to your dotfiles in `~/dotfiles`
2. The build script automatically copies current dotfiles
3. Rebuild the ISO with `sudo ./build.sh`

Alternatively, manually sync dotfiles:

```bash
# Remove old dotfiles from airootfs
rm -rf airootfs/root/dotfiles

# Copy current dotfiles (excluding archiso directory)
cp -r ~/dotfiles airootfs/root/
rm -rf airootfs/root/dotfiles/archiso
```

## Maintenance and Rebuilding

### When to Rebuild

Rebuild the ISO when:
- You update your dotfiles
- Arch packages have major updates
- You want to add/remove packages
- You modify the installer script

### Regular Updates

```bash
# Update package database
sudo pacman -Sy

# Rebuild ISO with latest packages
cd ~/dotfiles/archiso
sudo ./build.sh
```

### Cleaning Build Artifacts

```bash
# Remove work directory
sudo rm -rf /tmp/archiso-work

# Remove old ISOs
rm ~/arch-isos/custom-arch-*.iso
```

## Troubleshooting

### Build Fails

**Issue**: Package not found
- **Solution**: Remove the package from `packages.x86_64` or check if it's in AUR

**Issue**: Permission denied
- **Solution**: Run build script with sudo: `sudo ./build.sh`

**Issue**: Out of disk space
- **Solution**: Clean `/tmp/archiso-work` and ensure 10GB+ free space

### ISO Won't Boot

**Issue**: Black screen after boot
- **Solution**: Try different graphics drivers or add `nomodeset` to boot parameters

**Issue**: Kernel panic
- **Solution**: Check that `linux` and `linux-firmware` are in packages.x86_64

### Installation Issues

**Issue**: Disk not found
- **Solution**: Ensure disk is properly connected and recognized by BIOS/UEFI

**Issue**: GRUB installation fails
- **Solution**: Verify you're booting in UEFI mode (check `/sys/firmware/efi/efivars`)

**Issue**: Dotfiles not deploying
- **Solution**: After installation, manually run: `cd ~/dotfiles && ./install.sh`

## Advanced Configuration

### Multi-Architecture Support

The current build targets `x86_64` only. To add ARM support:

1. Create `packages.aarch64`
2. Modify `profiledef.sh` to include ARM architecture
3. Use a different build machine or cross-compilation

### Custom Kernel

To use a custom kernel:

1. Replace `linux` with your kernel in `packages.x86_64`
2. Ensure kernel modules are compatible
3. Update mkinitcpio hooks if needed

### Network Installation

To make a minimal ISO that downloads packages during install:

1. Remove most packages from `packages.x86_64`
2. Keep only: base, linux, linux-firmware, networkmanager
3. Modify installer to pacstrap additional packages

## Additional Resources

- [Archiso Official Documentation](https://wiki.archlinux.org/title/Archiso)
- [Arch Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
- [GNU Stow Documentation](https://www.gnu.org/software/stow/manual/)

## Version Information

This ISO build configuration is based on:
- **Archiso**: releng profile (latest)
- **Build System**: archiso package from official repos
- **Target Architecture**: x86_64 (UEFI + BIOS)

## License

Your dotfiles license applies to the configurations.
Arch Linux and included packages have their respective licenses.

## Support

For issues specific to:
- **ISO building**: Check Arch Wiki and archiso documentation
- **Your dotfiles**: Refer to your dotfiles repository
- **Arch installation**: See Arch Wiki Installation Guide

---

**Happy Installing! 🚀**
