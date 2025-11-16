#!/bin/bash
#
# Automated Arch Linux Installer
# Installs Arch Linux with your custom dotfiles configuration
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
║      Custom Arch Linux Installer with Dotfiles           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

echo ""
info "This script will install Arch Linux with your custom configurations"
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

# Step 3: Desktop Environment Selection
info "Step 3: Desktop Environment Selection"
echo ""
echo "1) KDE Plasma"
echo "2) Hyprland"
echo "3) Both (KDE + Hyprland)"
echo ""
read -p "Select desktop environment (1/2/3): " DE_CHOICE

case $DE_CHOICE in
    1) INSTALL_KDE=true; INSTALL_HYPRLAND=false ;;
    2) INSTALL_KDE=false; INSTALL_HYPRLAND=true ;;
    3) INSTALL_KDE=true; INSTALL_HYPRLAND=true ;;
    *) error "Invalid choice" ;;
esac

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

# Install desktop environment
if [ "$INSTALL_KDE" = "true" ]; then
    echo "Installing KDE Plasma..."
    pacman -S --noconfirm \
        plasma-desktop \
        plasma-nm \
        plasma-pa \
        plasma-workspace \
        sddm \
        konsole \
        dolphin \
        kate \
        ark \
        spectacle

    systemctl enable sddm
fi

if [ "$INSTALL_HYPRLAND" = "true" ]; then
    echo "Installing Hyprland..."
    pacman -S --noconfirm \
        hyprland \
        waybar \
        wofi \
        dunst \
        grim \
        slurp \
        wl-clipboard \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk
fi

# Enable NetworkManager
systemctl enable NetworkManager

# Install GRUB bootloader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Clone dotfiles
echo "Cloning dotfiles..."
if [ -d "/root/dotfiles" ]; then
    cp -r /root/dotfiles "/home/$USERNAME/dotfiles"
    chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/dotfiles"
fi

echo "Installation complete!"

CHROOT_EOF

# Replace placeholders
sed -i "s/__HOSTNAME__/$HOSTNAME/g" /mnt/root/configure.sh
sed -i "s/__USERNAME__/$USERNAME/g" /mnt/root/configure.sh
sed -i "s/__USER_PASSWORD__/$USER_PASSWORD/g" /mnt/root/configure.sh
sed -i "s/__ROOT_PASSWORD__/$ROOT_PASSWORD/g" /mnt/root/configure.sh
sed -i "s/__INSTALL_KDE__/$INSTALL_KDE/g" /mnt/root/configure.sh
sed -i "s/__INSTALL_HYPRLAND__/$INSTALL_HYPRLAND/g" /mnt/root/configure.sh

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
success "Arch Linux has been successfully installed!"
echo ""
info "Next steps:"
echo "1. The system will reboot automatically"
echo "2. Log in with username: $USERNAME"
echo "3. Run: cd ~/dotfiles && ./install.sh"
echo "4. Enjoy your configured system!"
echo ""

read -p "Press Enter to reboot..."

# Unmount and reboot
umount -R /mnt
swapoff -a
reboot
