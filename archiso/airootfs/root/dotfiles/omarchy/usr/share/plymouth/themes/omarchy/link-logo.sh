#!/bin/bash
# Script to create symlink for Plymouth logo.png from dotfiles
# This allows managing the boot logo through version control

DOTFILES_LOGO="/home/galib/dotfiles/omarchy/usr/share/plymouth/themes/omarchy/logo.png"
SYSTEM_LOGO="/usr/share/plymouth/themes/omarchy/logo.png"
BACKUP_LOGO="${SYSTEM_LOGO}.backup"

# Check if dotfiles logo exists
if [ ! -f "$DOTFILES_LOGO" ]; then
    echo "Error: Dotfiles logo not found at $DOTFILES_LOGO"
    exit 1
fi

# Create backup if system logo exists and is not already a symlink
if [ -f "$SYSTEM_LOGO" ] && [ ! -L "$SYSTEM_LOGO" ]; then
    echo "Creating backup of existing logo..."
    sudo cp "$SYSTEM_LOGO" "$BACKUP_LOGO"
    echo "Backup created at $BACKUP_LOGO"
fi

# Remove existing system logo (file or symlink)
if [ -e "$SYSTEM_LOGO" ] || [ -L "$SYSTEM_LOGO" ]; then
    echo "Removing existing system logo..."
    sudo rm "$SYSTEM_LOGO"
fi

# Create symlink
echo "Creating symlink..."
sudo ln -s "$DOTFILES_LOGO" "$SYSTEM_LOGO"

# Verify symlink
if [ -L "$SYSTEM_LOGO" ]; then
    echo "✓ Symlink created successfully!"
    echo "  $SYSTEM_LOGO -> $DOTFILES_LOGO"
    echo ""
    echo "You can now edit: $DOTFILES_LOGO"
    echo "Changes will automatically reflect in the system."
    echo ""
    echo "Rebuilding initramfs to apply Plymouth changes..."
    sudo mkinitcpio -P

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Initramfs rebuilt successfully!"
        echo "Reboot to see the changes at boot."
    else
        echo ""
        echo "✗ Failed to rebuild initramfs"
        echo "You may need to run 'sudo mkinitcpio -P' manually"
        exit 1
    fi
else
    echo "✗ Failed to create symlink"
    exit 1
fi
