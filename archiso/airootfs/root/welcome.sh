#!/bin/bash
#
# Welcome script for Custom Arch Linux Live Environment
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

# Banner
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║          Welcome to Custom Arch Linux Live Environment           ║
║                                                                   ║
║                     Configured with Dotfiles                      ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}Choose an option:${NC}"
echo ""
echo -e "${GREEN}1)${NC} Start KDE Plasma Desktop Environment (Live)"
echo -e "${GREEN}2)${NC} Start Hyprland (Live)"
echo -e "${GREEN}3)${NC} Install Arch Linux to Disk (Automated Installer)"
echo -e "${GREEN}4)${NC} Manual Installation (for advanced users)"
echo -e "${GREEN}5)${NC} Shell (Stay in terminal)"
echo ""
echo -e "${YELLOW}Note: Live environments include your dotfiles pre-configured!${NC}"
echo ""

read -p "Enter your choice (1-5): " CHOICE

case $CHOICE in
    1)
        echo -e "${BLUE}Starting KDE Plasma...${NC}"
        sleep 1
        exec startplasma-wayland
        ;;
    2)
        echo -e "${BLUE}Starting Hyprland...${NC}"
        sleep 1
        exec Hyprland
        ;;
    3)
        echo -e "${BLUE}Starting Automated Installer...${NC}"
        sleep 1
        exec /root/install-arch.sh
        ;;
    4)
        clear
        echo -e "${CYAN}Manual Installation Guide:${NC}"
        echo ""
        echo "1. Partition your disk with: fdisk, cfdisk, or parted"
        echo "2. Format partitions: mkfs.ext4, mkfs.fat, mkswap"
        echo "3. Mount partitions: mount /dev/sdXn /mnt"
        echo "4. Install base system: pacstrap /mnt base linux linux-firmware"
        echo "5. Generate fstab: genfstab -U /mnt >> /mnt/etc/fstab"
        echo "6. Chroot: arch-chroot /mnt"
        echo ""
        echo "For detailed instructions, see: https://wiki.archlinux.org/title/Installation_guide"
        echo ""
        echo "Your dotfiles are available at: /root/dotfiles"
        echo "Installation script reference: /root/install-arch.sh"
        echo ""
        ;;
    5)
        clear
        echo -e "${GREEN}Entering shell...${NC}"
        echo ""
        echo "Available tools:"
        echo "  - Automated installer: /root/install-arch.sh"
        echo "  - Your dotfiles: /root/dotfiles"
        echo "  - This welcome screen: /root/welcome.sh"
        echo ""
        ;;
    *)
        echo -e "${RED}Invalid choice. Entering shell...${NC}"
        sleep 2
        ;;
esac
