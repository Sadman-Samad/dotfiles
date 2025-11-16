#!/bin/bash
#
# Welcome script for Galib OS Live Environment
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
║                    Welcome to Galib OS                            ║
║                                                                   ║
║         Galib OS - Arch Linux + Omarchy + Custom Dotfiles          ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${CYAN}Choose an option:${NC}"
echo ""
echo -e "${GREEN}1)${NC} Start Hyprland (Live Environment)"
echo -e "${GREEN}2)${NC} Install Galib OS to Disk (Automated Installer)"
echo -e "${GREEN}3)${NC} Manual Installation (for advanced users)"
echo -e "${GREEN}4)${NC} Shell (Stay in terminal)"
echo ""
echo -e "${YELLOW}Note: Hyprland and all your dotfiles are pre-configured!${NC}"
echo ""

read -p "Enter your choice (1-4): " CHOICE

case $CHOICE in
    1)
        echo -e "${BLUE}Starting Hyprland...${NC}"
        echo -e "${YELLOW}Creating temporary user for Wayland session...${NC}"
        sleep 1

        # Create temporary user if not exists
        if ! id -u liveuser &>/dev/null; then
            useradd -m -G wheel,audio,video,input,seat -s /bin/zsh liveuser
            echo "liveuser:live" | chpasswd
        fi

        # Sync dotfiles to liveuser
        if [ ! -d "/home/liveuser/dotfiles" ]; then
            /root/sync-dotfiles.sh liveuser
        fi

        # Set up XDG_RUNTIME_DIR for the user
        LIVEUSER_UID=$(id -u liveuser)
        mkdir -p /run/user/$LIVEUSER_UID
        chown liveuser:liveuser /run/user/$LIVEUSER_UID
        chmod 700 /run/user/$LIVEUSER_UID

        # Switch to liveuser and start Hyprland with proper environment
        echo -e "${GREEN}Starting Hyprland as 'liveuser'...${NC}"
        echo -e "${CYAN}(Password is 'live' if needed)${NC}"
        sleep 1

        su -l liveuser << EOF
export XDG_RUNTIME_DIR=/run/user/$LIVEUSER_UID
export XDG_SESSION_TYPE=wayland
exec dbus-run-session Hyprland
EOF
        ;;
    2)
        echo -e "${BLUE}Starting Automated Installer...${NC}"
        sleep 1
        exec /root/install-arch.sh
        ;;
    3)
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
    4)
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
