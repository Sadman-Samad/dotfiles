#!/bin/bash
#
# Galib OS Installer
# Installs Galib OS (Arch Linux + Omarchy + Custom Dotfiles)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              Galib OS Installer                           ║
║                                                           ║
║      Arch Linux + Omarchy + Custom Dotfiles               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
info "This script will install Galib OS with your custom configurations"
echo ""

# Check if running in UEFI mode
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    error "This installer requires UEFI mode. Please boot in UEFI mode."
fi

# Step 1: Disk Selection
info "Step 1: Disk Selection"
echo ""
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
echo ""
read -p "Enter the disk to install Arch Linux (e.g., /dev/sda or /dev/nvme0n1): " DISK

if [ ! -b "$DISK" ]; then
    error "Invalid disk: $DISK"
fi

warning "WARNING: ALL DATA ON $DISK WILL BE ERASED!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    error "Installation cancelled by user."
fi

# Step 2: System Information
info "Step 2: System Configuration"
read -p "Enter hostname for this system: " HOSTNAME
read -p "Enter username: " USERNAME
read -sp "Enter password for $USERNAME: " USER_PASSWORD
echo ""
read -sp "Enter root password: " ROOT_PASSWORD
echo ""

# Step 3: Confirm Installation
info "Step 3: Confirm Installation"
echo ""
echo "Desktop Environment: Hyprland (with Omarchy)"
echo "Dotfiles: Pre-configured from ~/dotfiles"
echo ""
read -p "Continue with installation? (yes/no): " INSTALL_CONFIRM

if [ "$INSTALL_CONFIRM" != "yes" ]; then
    error "Installation cancelled by user."
fi

# Set installation flags
INSTALL_KDE=false
INSTALL_HYPRLAND=true

# Step 4: Partitioning
info "Step 4: Partitioning the disk..."

# Unmount if mounted
umount -R /mnt 2>/dev/null || true

# Determine partition naming scheme
if [[ "$DISK" =~ "nvme" ]] || [[ "$DISK" =~ "mmcblk" ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

EFI_PART="${PART_PREFIX}1"
SWAP_PART="${PART_PREFIX}2"
ROOT_PART="${PART_PREFIX}3"

# Wipe disk
wipefs -a "$DISK"

# Create GPT partition table
parted -s "$DISK" mklabel gpt

# Create partitions
# EFI partition (512MB)
parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# Swap partition (8GB)
parted -s "$DISK" mkpart primary linux-swap 513MiB 8705MiB

# Root partition (remaining space)
parted -s "$DISK" mkpart primary ext4 8705MiB 100%

# Wait for devices to be recognized
sleep 2

# Format partitions
info "Formatting partitions..."
mkfs.fat -F32 "$EFI_PART"
mkswap "$SWAP_PART"
mkfs.ext4 -F "$ROOT_PART"

# Mount partitions
info "Mounting partitions..."
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot
swapon "$SWAP_PART"

success "Partitioning complete!"

# Step 5: Install base system
info "Step 5: Installing base system... (this may take a while)"

# Update mirrors
reflector --country US,Canada --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install base packages
pacstrap /mnt base linux linux-firmware base-devel

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

success "Base system installed!"

# Step 6: Configure system
info "Step 6: Configuring system..."

# Create configuration script to run in chroot
cat > /mnt/root/configure.sh << 'CHROOT_EOF'
#!/bin/bash

set -e

HOSTNAME="__HOSTNAME__"
USERNAME="__USERNAME__"
USER_PASSWORD="__USER_PASSWORD__"
ROOT_PASSWORD="__ROOT_PASSWORD__"
INSTALL_KDE="__INSTALL_KDE__"
INSTALL_HYPRLAND="__INSTALL_HYPRLAND__"

# Set timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc

# Localization
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "$HOSTNAME" > /etc/hostname

# Hosts file
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel,audio,video,optical,storage -s /bin/zsh "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Enable sudo for wheel group
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install essential packages
pacman -S --noconfirm \
    networkmanager \
    git \
    stow \
    neovim \
    tmux \
    zsh \
    wget \
    curl \
    unzip \
    firefox \
    grub \
    efibootmgr \
    os-prober

# Install Hyprland desktop environment
echo "Installing Hyprland with Omarchy..."
pacman -S --noconfirm \
    hyprland \
    waybar \
    wofi \
    rofi \
    dunst \
    mako \
    grim \
    slurp \
    wl-clipboard \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    qt5ct \
    kvantum \
    swaylock \
    swayidle

# Don't enable a display manager - we'll auto-login to Hyprland

# Install Omarchy base system
echo "Installing Omarchy..."

# Copy Omarchy system files from live environment if available
if [ -d "/usr/share/omarchy" ]; then
    echo "Omarchy system files found, copying..."
    cp -r /usr/share/omarchy /usr/share/
fi

# Install Omarchy package if available
# pacman -S --noconfirm omarchy || echo "Omarchy package not found, using bundled files"

# Enable NetworkManager
systemctl enable NetworkManager

# Install yay and AUR packages
echo "Installing yay and AUR packages..."
/root/install-aur-packages.sh

# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Install and configure Plymouth
echo "Configuring Plymouth boot splash..."
pacman -S --noconfirm plymouth

# Copy Plymouth theme if available
if [ -d "/usr/share/plymouth/themes/galibos" ]; then
    echo "Plymouth theme already installed"
else
    echo "Note: Plymouth theme will be available after reboot"
fi

# Set Plymouth theme
plymouth-set-default-theme -R text 2>/dev/null || echo "Using default text theme"

# Update initramfs for Plymouth
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf

# Rebuild initramfs
mkinitcpio -P

# Update GRUB configuration for Plymouth
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/' /etc/default/grub

# Regenerate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg

# Create Galib OS identification
cat > /etc/os-release << 'EOF'
NAME="Galib OS"
PRETTY_NAME="Galib OS"
ID=galibos
ID_LIKE=arch
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://github.com/yourusername/dotfiles"
DOCUMENTATION_URL="https://github.com/yourusername/dotfiles"
SUPPORT_URL="https://github.com/yourusername/dotfiles"
BUG_REPORT_URL="https://github.com/yourusername/dotfiles/issues"
LOGO=galibos
EOF

# Clone and setup dotfiles
echo "Setting up dotfiles..."
if [ -d "/root/dotfiles" ]; then
    # Copy from live environment
    cp -r /root/dotfiles "/home/$USERNAME/dotfiles"
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/dotfiles"

    # Install dotfiles
    echo "Installing dotfiles..."
    cd "/home/$USERNAME/dotfiles"

    # Run install script as user
    sudo -u "$USERNAME" ./install.sh

    cd /root
else
    echo "Warning: Dotfiles not found in live environment"
fi

echo "Dotfiles setup complete!"

# Configure auto-login to Hyprland
echo "Configuring auto-login..."

# Create systemd drop-in for getty@tty1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USERNAME - \$TERM
EOF

# Create .zprofile for auto-starting Hyprland
cat > /home/$USERNAME/.zprofile << 'EOF'
# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec Hyprland
fi
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/.zprofile

CHROOT_EOF

# Replace placeholders
sed -i "s/__HOSTNAME__/$HOSTNAME/g" /mnt/root/configure.sh
sed -i "s/__USERNAME__/$USERNAME/g" /mnt/root/configure.sh
sed -i "s/__USER_PASSWORD__/$USER_PASSWORD/g" /mnt/root/configure.sh
sed -i "s/__ROOT_PASSWORD__/$ROOT_PASSWORD/g" /mnt/root/configure.sh

# Make script executable
chmod +x /mnt/root/configure.sh

# Copy dotfiles to mounted root
if [ -d "/root/dotfiles" ]; then
    cp -r /root/dotfiles /mnt/root/
fi

# Run configuration in chroot
arch-chroot /mnt /root/configure.sh

# Cleanup
rm /mnt/root/configure.sh

success "System configuration complete!"

# Step 7: Post-installation instructions
info "Step 7: Installation Complete!"
echo ""
success "Galib OS has been successfully installed!"
echo ""
info "Next steps:"
echo "1. The system will reboot automatically"
echo "2. Log in with username: $USERNAME"
echo "3. Hyprland will start automatically"
echo "4. Your dotfiles are already installed at ~/dotfiles"
echo "5. Enjoy your configured system!"
echo ""

read -p "Press Enter to reboot..."

# Unmount and reboot
umount -R /mnt
swapoff -a
reboot
