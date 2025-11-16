# Galib OS - Comprehensive Implementation Plan

## Table of Contents
1. [Overview & Architecture](#overview--architecture)
2. [Prerequisites](#prerequisites)
3. [Phase-by-Phase Implementation](#phase-by-phase-implementation)
4. [File Modifications Reference](#file-modifications-reference)
5. [Complete Package List](#complete-package-list)
6. [Build & Test Commands](#build--test-commands)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview & Architecture

### What is Galib OS?
Galib OS is a custom Arch Linux distribution built on top of Omarchy (a Hyprland-based Arch distro) with your personal dotfiles pre-configured. The ISO provides a live environment and installer that sets up a fully-configured system.

### Architecture Overview
```
┌─────────────────────────────────────────────────────────────┐
│                     Galib OS ISO                            │
├─────────────────────────────────────────────────────────────┤
│  Base: Arch Linux + Omarchy (Hyprland)                     │
│  Branding: "Galib OS" (all references replaced)            │
│  Desktop: Hyprland only (KDE removed)                       │
│  Boot: Plymouth → Auto-boot Hyprland (no menu)             │
│  Dotfiles: Pre-installed at ~/dotfiles/                    │
│    ├─ omarchy (Hyprland configs from Omarchy)              │
│    ├─ zsh (default shell with p10k)                        │
│    ├─ nvim (Neovim configuration)                          │
│    ├─ tmux (terminal multiplexer)                          │
│    ├─ bin (utility scripts)                                │
│    ├─ claude-code (AI assistant configs)                   │
│    ├─ obsidian (note-taking setup)                         │
│    ├─ alacritty, kitty, ghostty, wezterm (terminals)      │
│    ├─ waybar (status bar for Hyprland)                    │
│    ├─ vscode (editor with Vim mode)                        │
│    ├─ zen-browser (browser)                                │
│    └─ boot (boot configuration)                            │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Omarchy Integration**: Bundle Omarchy as the base system instead of rebuilding from scratch
2. **No KDE**: Remove all Plasma packages to reduce bloat and boot directly to Hyprland
3. **Auto-boot**: Skip boot menu, go straight to Hyprland live environment
4. **Complete Branding**: Replace all "Omarchy" and "Arch Linux" references with "Galib OS"
5. **Dotfiles-First**: All configurations come from your dotfiles repo at ~/dotfiles

---

## Prerequisites

### Required Packages on Build System
```bash
# Install archiso and dependencies
sudo pacman -S archiso git

# Optional but recommended
sudo pacman -S rsync tree
```

### Required Knowledge
- Basic understanding of Arch Linux installation
- Familiarity with archiso build process
- Understanding of systemd and Plymouth
- Knowledge of your dotfiles structure

### Build System Requirements
- Arch Linux system (VM or bare metal)
- At least 10GB free disk space
- Internet connection for downloading packages
- Root/sudo access

### Current File Structure
Your archiso directory should have:
```
/home/galib/dotfiles/archiso/
├── packages.x86_64          # Package list for ISO
├── profiledef.sh            # ISO metadata and configuration
├── pacman.conf             # Pacman configuration
├── bootstrap_packages      # Bootstrap package list
├── airootfs/               # Root filesystem overlay
│   ├── etc/                # System configuration files
│   ├── root/               # Root user files
│   │   ├── dotfiles/       # Your dotfiles (to be synced)
│   │   ├── install-arch.sh # Installation script
│   │   └── welcome.sh      # Welcome menu
│   └── usr/                # User binaries and data
├── efiboot/                # EFI boot configuration
├── grub/                   # GRUB configuration
└── syslinux/               # SYSLINUX configuration
```

---

## Phase-by-Phase Implementation

### Phase 1: Remove KDE and Update Base Packages

#### Step 1.1: Remove KDE Packages from packages.x86_64
**File**: `/home/galib/dotfiles/archiso/packages.x86_64`

**Action**: Remove all KDE-related packages (lines 118-132)

Remove these packages:
```bash
plasma-desktop
plasma-nm
plasma-pa
plasma-workspace
kscreen
powerdevil
sddm
konsole
dolphin
kate
ark
spectacle
gwenview
okular
```

**Why**: KDE adds ~500MB to the ISO and we're using Hyprland exclusively.

#### Step 1.2: Add Missing Hyprland Dependencies

Add these packages after the existing Hyprland section (around line 146):
```bash
# Additional Hyprland components
rofi
swaylock
swayidle
mako
polkit-kde-agent
qt5ct
kvantum
```

**Why**: These are essential for a complete Hyprland experience.

#### Step 1.3: Add Omarchy Package

Add to the end of packages.x86_64:
```bash
# Omarchy base distribution
# Note: If omarchy is in AUR, you'll need to build it first
# For now, we'll install its dependencies and config manually
```

**Important**: Check if Omarchy is available as a package. If not, we'll need to:
1. Install Omarchy dependencies manually
2. Copy Omarchy configuration files from `/home/galib/dotfiles/omarchy/`

#### Step 1.4: Add Terminal Emulators

Ensure these are present:
```bash
# Terminal emulators (already present)
alacritty
kitty

# Add if not present:
ghostty      # Check if available in repos/AUR
wezterm
```

#### Step 1.5: Add Additional Tools

Add after line 113:
```bash
# Additional dotfiles utilities
lazygit
lazydocker
delta
procs
bottom
tokei
hyperfine
```

---

### Phase 2: Add Omarchy Dependencies and Configuration

#### Step 2.1: Create Omarchy Setup Script

**File**: `/home/galib/dotfiles/archiso/airootfs/root/setup-omarchy.sh`

**Create new file**:
```bash
#!/bin/bash
#
# Setup script for Omarchy base system
# This installs Omarchy and configures it for Galib OS
#

set -e

OMARCHY_DIR="/home/galib/dotfiles/omarchy"
SHARE_DIR="/usr/share/omarchy"
CONFIG_DIR="/etc/omarchy"

echo "Setting up Omarchy base system..."

# Create system directories
mkdir -p "$SHARE_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p /usr/share/plymouth/themes/galibos

# Install Omarchy defaults to system
if [ -d "$OMARCHY_DIR" ]; then
    # Copy Omarchy system files
    if [ -d "$OMARCHY_DIR/usr" ]; then
        cp -r "$OMARCHY_DIR/usr/"* /usr/ 2>/dev/null || true
    fi

    # Copy Omarchy configs
    if [ -d "$OMARCHY_DIR/.config" ]; then
        mkdir -p /usr/share/omarchy/default
        cp -r "$OMARCHY_DIR/.config/"* /usr/share/omarchy/default/
    fi

    echo "Omarchy system files installed"
else
    echo "Warning: Omarchy directory not found at $OMARCHY_DIR"
fi

# Setup Plymouth theme
setup_plymouth_theme() {
    local theme_dir="/usr/share/plymouth/themes/galibos"

    # Create theme directory
    mkdir -p "$theme_dir"

    # Check if we have Omarchy Plymouth files
    if [ -f "$OMARCHY_DIR/usr/share/plymouth/themes/omarchy/logo.png" ]; then
        # Copy and rename logo
        cp "$OMARCHY_DIR/usr/share/plymouth/themes/omarchy/logo.png" \
           "$theme_dir/logo.png"
    fi

    # Create Plymouth theme file
    cat > "$theme_dir/galibos.plymouth" << 'EOF'
[Plymouth Theme]
Name=Galib OS
Description=Galib OS Boot Splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/galibos
ScriptFile=/usr/share/plymouth/themes/galibos/galibos.script
EOF

    # Create basic Plymouth script
    cat > "$theme_dir/galibos.script" << 'EOF'
# Galib OS Plymouth Theme Script
Window.SetBackgroundTopColor(0.00, 0.00, 0.00);
Window.SetBackgroundBottomColor(0.10, 0.10, 0.10);

logo.image = Image("logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetPosition(Window.GetWidth() / 2 - logo.image.GetWidth() / 2,
                        Window.GetHeight() / 2 - logo.image.GetHeight() / 2,
                        10000);

status = "Galib OS";

message_sprite = SpriteNew();
message_sprite.SetPosition(10, 10, 10000);

fun message_callback(text) {
    my_image = ImageText(text, 1, 1, 1);
    message_sprite.SetImage(my_image);
}

Plymouth.SetMessageFunction(message_callback);
EOF

    echo "Plymouth theme created at $theme_dir"
}

setup_plymouth_theme

# Configure Hyprland to use system defaults
echo "Configuring Hyprland..."
mkdir -p /etc/skel/.config/hypr
cat > /etc/skel/.config/hypr/hyprland.conf << 'EOF'
# Galib OS Hyprland Configuration
# This sources both Omarchy defaults and your custom configs

# Source Omarchy defaults
source = /usr/share/omarchy/default/hypr/autostart.conf
source = /usr/share/omarchy/default/hypr/bindings/media.conf
source = /usr/share/omarchy/default/hypr/bindings/tiling.conf
source = /usr/share/omarchy/default/hypr/bindings/utilities.conf
source = /usr/share/omarchy/default/hypr/envs.conf
source = /usr/share/omarchy/default/hypr/looknfeel.conf
source = /usr/share/omarchy/default/hypr/input.conf
source = /usr/share/omarchy/default/hypr/windows.conf

# Source your custom overrides
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/input.conf
source = ~/.config/hypr/bindings.conf
source = ~/.config/hypr/envs.conf
source = ~/.config/hypr/looknfeel.conf
source = ~/.config/hypr/autostart.conf
EOF

echo "Omarchy setup complete!"
```

**Set permissions** in profiledef.sh (we'll add this in Phase 4).

#### Step 2.2: Sync Omarchy Files to airootfs

**Action**: Copy Omarchy files to the ISO root filesystem

```bash
# Run this on your build system before building ISO
cd /home/galib/dotfiles/archiso/airootfs/root/dotfiles

# If omarchy directory doesn't exist in airootfs, create it
mkdir -p omarchy

# Copy from your actual dotfiles
rsync -av --exclude='.git' \
    /home/galib/dotfiles/omarchy/ \
    /home/galib/dotfiles/archiso/airootfs/root/dotfiles/omarchy/
```

**Why**: We need Omarchy configs in the ISO so they can be installed system-wide.

#### Step 2.3: Create Omarchy System Service

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/systemd/system/galibos-setup.service`

**Create new file**:
```systemd
[Unit]
Description=Galib OS Initial Setup
After=multi-user.target
Before=getty@tty1.service

[Service]
Type=oneshot
ExecStart=/root/setup-omarchy.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable the service** (we'll add this to airootfs setup script).

---

### Phase 3: Configure Dotfiles Integration

#### Step 3.1: Update Dotfiles Sync Script

**File**: `/home/galib/dotfiles/archiso/airootfs/root/sync-dotfiles.sh`

**Create new file**:
```bash
#!/bin/bash
#
# Sync dotfiles from live environment to installed system
# Excludes hyprland/ directory as requested
#

set -e

SOURCE_DIR="/root/dotfiles"
TARGET_USER="${1:-liveuser}"
TARGET_HOME="/home/$TARGET_USER"
TARGET_DOTFILES="$TARGET_HOME/dotfiles"

echo "Syncing dotfiles to $TARGET_HOME..."

# Create target directory
mkdir -p "$TARGET_DOTFILES"

# List of packages to include (excludes hyprland/)
PACKAGES=(
    "omarchy"
    "zsh"
    "nvim"
    "tmux"
    "bin"
    "claude-code"
    "obsidian"
    "alacritty"
    "kitty"
    "ghostty"
    "wezterm"
    "waybar"
    "p10k"
    "vscode"
    "zen-browser"
    "boot"
)

# Also copy root-level files
rsync -av --exclude='.git' \
    "$SOURCE_DIR/install.sh" \
    "$SOURCE_DIR/stowup" \
    "$SOURCE_DIR/stowDown" \
    "$SOURCE_DIR/README.md" \
    "$SOURCE_DIR/CLAUDE.md" \
    "$TARGET_DOTFILES/" 2>/dev/null || true

# Sync each package
for package in "${PACKAGES[@]}"; do
    if [ -d "$SOURCE_DIR/$package" ]; then
        echo "  - Syncing $package..."
        rsync -av --exclude='.git' \
            "$SOURCE_DIR/$package/" \
            "$TARGET_DOTFILES/$package/"
    else
        echo "  - Warning: Package $package not found, skipping"
    fi
done

# Set ownership
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_DOTFILES"

echo "Dotfiles synced successfully!"
echo ""
echo "Packages synced:"
printf '  - %s\n' "${PACKAGES[@]}"
echo ""
echo "To install dotfiles, run:"
echo "  cd ~/dotfiles && ./install.sh"
```

**Set executable** in profiledef.sh.

#### Step 3.2: Update install.sh to Handle Package Subset

**Note**: Your existing install.sh in dotfiles should handle selective stowing. Verify it works with:
```bash
# Test on your system
cd /home/galib/dotfiles
./stowup omarchy
./stowup zsh
# etc.
```

If install.sh doesn't support selective packages, update it to detect available packages automatically.

#### Step 3.3: Pre-configure Zsh as Default Shell

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/passwd`

**Modify the root user entry** (should be around line 1):
```
root:x:0:0:root:/root:/bin/zsh
```

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/skel/.zshrc`

**Create new file** (basic zsh config for new users):
```bash
# Galib OS - Default Zsh Configuration
# This is the initial config; full config is in ~/dotfiles/zsh

# If dotfiles exist, source the full configuration
if [ -d "$HOME/dotfiles/zsh" ]; then
    # Dotfiles are installed, skip this and use stowed config
    :
else
    # Basic prompt until dotfiles are installed
    PS1='%F{cyan}galib-os%f %F{yellow}%~%f %# '

    # Basic aliases
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias vim='nvim'

    # Remind user to install dotfiles
    echo ""
    echo "Welcome to Galib OS!"
    echo "Install your dotfiles with: cd ~/dotfiles && ./install.sh"
    echo ""
fi
```

---

### Phase 4: Complete System Branding

This is the most extensive phase. We need to replace all references to "Omarchy" and "Arch Linux" with "Galib OS".

#### Step 4.1: Update ISO Metadata

**File**: `/home/galib/dotfiles/archiso/profiledef.sh`

**Before**:
```bash
iso_name="custom-arch"
iso_label="CUSTOMARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Custom Arch Linux with Dotfiles"
iso_application="Custom Arch Linux Live/Install Environment"
```

**After**:
```bash
iso_name="galibos"
iso_label="GALIBOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Galib OS - Arch Linux with Omarchy and Custom Dotfiles"
iso_application="Galib OS Live/Install Environment"
```

**Add permissions** for new scripts (add to file_permissions array):
```bash
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/root/install-arch.sh"]="0:0:755"
  ["/root/welcome.sh"]="0:0:755"
  ["/root/setup-omarchy.sh"]="0:0:755"
  ["/root/sync-dotfiles.sh"]="0:0:755"
  ["/root/dotfiles/install.sh"]="0:0:755"
  ["/root/dotfiles/stowup"]="0:0:755"
  ["/root/dotfiles/stowDown"]="0:0:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
```

#### Step 4.2: Update /etc/os-release

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/os-release`

**Create new file**:
```bash
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
```

**Why**: This is what `neofetch`, `fastfetch`, and other tools read for OS information.

#### Step 4.3: Update /etc/issue

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/issue`

**Create new file**:
```
Galib OS \r (\l)
```

**Why**: This is shown at the login prompt.

#### Step 4.4: Update Hostname

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/hostname`

**Before**:
```
archiso
```

**After**:
```
galibos
```

#### Step 4.5: Update MOTD (Message of the Day)

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/motd`

**Before**:
```
To install [38;2;23;147;209mArch Linux[0m follow the installation guide:
https://wiki.archlinux.org/title/Installation_guide
...
```

**After**:
```
[38;2;23;147;209m╔═══════════════════════════════════════════════════════════╗[0m
[38;2;23;147;209m║                                                           ║[0m
[38;2;23;147;209m║                    Welcome to Galib OS                    ║[0m
[38;2;23;147;209m║                                                           ║[0m
[38;2;23;147;209m║          Arch Linux + Omarchy + Custom Dotfiles           ║[0m
[38;2;23;147;209m║                                                           ║[0m
[38;2;23;147;209m╚═══════════════════════════════════════════════════════════╝[0m

This is a live environment. You can:

  • Install Galib OS to disk: [35m/root/install-arch.sh[0m
  • Start Hyprland: [35m/root/welcome.sh[0m
  • Access your dotfiles: [35mcd /root/dotfiles[0m

For Wi-Fi: [35miwctl[0m  |  For help: [35m/root/welcome.sh[0m

System documentation: ~/dotfiles/README.md

[41m [41m [41m [40m [44m [40m [41m [46m [45m [41m [46m [43m [41m [44m [45m [40m [44m [40m [41m [44m [41m [41m [46m [42m [41m [44m [43m [41m [45m [40m [40m [44m [40m [41m [44m [42m [41m [46m [44m [41m [46m [47m [0m
```

#### Step 4.6: Update Welcome Script

**File**: `/home/galib/dotfiles/archiso/airootfs/root/welcome.sh`

**Before** (line 18-26):
```bash
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║          Welcome to Custom Arch Linux Live Environment           ║
║                                                                   ║
║                     Configured with Dotfiles                      ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
```

**After**:
```bash
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    Welcome to Galib OS                            ║
║                                                                   ║
║         Arch Linux + Omarchy + Custom Dotfiles                    ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
```

**Update options** (line 29-36):
```bash
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
```

**Update case statement** (remove KDE option):
```bash
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
```

#### Step 4.7: Update Installer Script

**File**: `/home/galib/dotfiles/archiso/airootfs/root/install-arch.sh`

**Update banner** (line 36-42):
```bash
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
```

**Remove KDE installation** (lines 80-94):

**Before**:
```bash
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
```

**After**:
```bash
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
```

**Update configure.sh in chroot** (remove KDE installation section):

**Remove** (lines 223-239):
```bash
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
```

**Update to**:
```bash
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
    kvantum

# Don't enable a display manager - we'll auto-login to Hyprland
```

**Update final instructions** (around line 298):
```bash
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
```

**Remove unnecessary variables** in the sed section (lines 273-279):

**Remove these lines**:
```bash
sed -i "s/__INSTALL_KDE__/$INSTALL_KDE/g" /mnt/root/configure.sh
sed -i "s/__INSTALL_HYPRLAND__/$INSTALL_HYPRLAND/g" /mnt/root/configure.sh
```

And update the configure.sh template to remove those placeholders.

#### Step 4.8: Update Boot Loader Configurations

**GRUB Configuration**

**File**: `/home/galib/dotfiles/archiso/grub/grub.cfg`

Search for "Arch Linux" and replace with "Galib OS":
```bash
# Find all occurrences (there may be multiple)
sed -i 's/Arch Linux/Galib OS/g' grub.cfg
```

**Example entry**:
```
menuentry "Galib OS (x86_64, UEFI)" {
    ...
}
```

**Systemd-boot Configuration**

**File**: `/home/galib/dotfiles/archiso/efiboot/loader/loader.conf`

```bash
timeout 0
default 01-galibos-linux.conf
```

**File**: `/home/galib/dotfiles/archiso/efiboot/loader/entries/01-archiso-linux.conf`

**Rename to**: `01-galibos-linux.conf`

**Content**:
```
title   Galib OS
linux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-linux
initrd  /%INSTALL_DIR%/boot/x86_64/initramfs-linux.img
options archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% quiet splash
```

**Update other entries**:
- `02-archiso-speech-linux.conf` → Remove or rename to `02-galibos-speech-linux.conf`
- `03-archiso-memtest86+x64.conf` → Rename to `03-galibos-memtest86+x64.conf`

**SYSLINUX Configuration**

**File**: `/home/galib/dotfiles/archiso/syslinux/archiso_head.cfg`

Replace "Arch Linux" with "Galib OS".

**File**: `/home/galib/dotfiles/archiso/syslinux/archiso_sys.cfg`

Update menu labels:
```
LABEL galibos
MENU LABEL Galib OS (x86_64, BIOS)
...
```

#### Step 4.9: Update Fastfetch/Neofetch

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/skel/.config/fastfetch/config.jsonc`

**Create new file**:
```jsonc
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "source": "arch",
        "padding": {
            "top": 1,
            "left": 2
        }
    },
    "display": {
        "separator": " -> "
    },
    "modules": [
        {
            "type": "custom",
            "format": "╔═══════════════════════════════════════╗"
        },
        {
            "type": "custom",
            "format": "║        Galib OS System Info        ║"
        },
        {
            "type": "custom",
            "format": "╚═══════════════════════════════════════╝"
        },
        "break",
        {
            "type": "os",
            "key": "OS",
            "keyColor": "cyan"
        },
        {
            "type": "kernel",
            "key": "Kernel",
            "keyColor": "cyan"
        },
        {
            "type": "packages",
            "key": "Packages",
            "keyColor": "cyan"
        },
        {
            "type": "shell",
            "key": "Shell",
            "keyColor": "cyan"
        },
        {
            "type": "wm",
            "key": "WM",
            "keyColor": "cyan"
        },
        "break",
        {
            "type": "terminal",
            "key": "Terminal",
            "keyColor": "yellow"
        },
        {
            "type": "cpu",
            "key": "CPU",
            "keyColor": "yellow"
        },
        {
            "type": "gpu",
            "key": "GPU",
            "keyColor": "yellow"
        },
        {
            "type": "memory",
            "key": "Memory",
            "keyColor": "yellow"
        },
        "break",
        {
            "type": "uptime",
            "key": "Uptime",
            "keyColor": "green"
        },
        "break",
        "colors"
    ]
}
```

#### Step 4.10: Create Custom Branding Files

**File**: `/home/galib/dotfiles/archiso/airootfs/usr/share/galibos/about.txt`

**Create new file**:
```
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                      Galib OS                             ║
║                                                           ║
║        Arch Linux + Omarchy + Custom Dotfiles             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Version: Rolling
Base: Arch Linux
Desktop: Hyprland (Omarchy)
Configuration: Custom Dotfiles

Features:
  • Hyprland tiling window manager
  • Pre-configured development environment
  • Vim-centric keybindings
  • Catppuccin Mocha theme
  • Multiple terminal emulators (Alacritty, Kitty, Ghostty, Wezterm)
  • Neovim with LazyVim
  • Tmux with custom configuration
  • Zsh with Powerlevel10k
  • VS Code with Vim mode
  • Claude Code AI assistant integration
  • Obsidian for note-taking

Repository: https://github.com/yourusername/dotfiles
```

---

### Phase 5: Plymouth Boot Splash Configuration

Plymouth provides the graphical boot splash screen with "Galib OS" branding.

#### Step 5.1: Install Plymouth Package

**File**: `/home/galib/dotfiles/archiso/packages.x86_64`

Add after line 42 (after mkinitcpio):
```bash
plymouth
```

#### Step 5.2: Create Plymouth Theme

Already handled in the `setup-omarchy.sh` script (Phase 2), but let's add additional configuration.

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/plymouth/plymouthd.conf`

**Create new file**:
```ini
[Daemon]
Theme=galibos
ShowDelay=0
DeviceTimeout=8
```

#### Step 5.3: Configure mkinitcpio for Plymouth

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/mkinitcpio.conf.d/plymouth.conf`

**Create new file**:
```bash
# Plymouth boot splash configuration
# Add plymouth to HOOKS

HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)
```

**Note**: This will be merged with the main mkinitcpio configuration.

#### Step 5.4: Update Kernel Parameters for Plymouth

**File**: `/home/galib/dotfiles/archiso/grub/grub.cfg`

Add `quiet splash` to kernel parameters:
```
linux /%INSTALL_DIR%/boot/x86_64/vmlinuz-linux ... quiet splash plymouth.ignore-serial-consoles
```

**File**: `/home/galib/dotfiles/archiso/efiboot/loader/entries/01-galibos-linux.conf`

Add to options line:
```
options ... quiet splash plymouth.ignore-serial-consoles
```

#### Step 5.5: Create Plymouth Logo

**File**: Create or update the logo at:
`/home/galib/dotfiles/omarchy/usr/share/plymouth/themes/omarchy/logo.png`

You'll need to create a custom logo for Galib OS. Options:

1. **Design a new logo** (recommended)
2. **Use Arch Linux logo** with "Galib OS" text
3. **Modify Omarchy logo** to say "Galib OS"

**Quick temporary solution** (use Arch logo):
```bash
# Copy Arch Linux logo from system
cp /usr/share/pixmaps/archlinux-logo.png \
   /home/galib/dotfiles/omarchy/usr/share/plymouth/themes/omarchy/logo.png
```

#### Step 5.6: Enable Plymouth in Live Environment

**File**: `/home/galib/dotfiles/archiso/airootfs/root/setup-omarchy.sh`

Add at the end (before "echo 'Omarchy setup complete!'"):
```bash
# Enable Plymouth
echo "Enabling Plymouth boot splash..."
plymouth-set-default-theme -R galibos 2>/dev/null || true
```

---

### Phase 6: Auto-boot Hyprland Configuration

Remove boot menu and go straight to Hyprland live environment.

#### Step 6.1: Set Systemd-boot Timeout to Zero

**File**: `/home/galib/dotfiles/archiso/efiboot/loader/loader.conf`

**Update**:
```
timeout 0
default 01-galibos-linux.conf
console-mode max
editor no
```

**Why**: `timeout 0` means no wait, boot immediately.

#### Step 6.2: Update GRUB Timeout

**File**: `/home/galib/dotfiles/archiso/grub/grub.cfg`

Add at the top:
```
set timeout=0
set default=0
```

#### Step 6.3: Update SYSLINUX Timeout

**File**: `/home/galib/dotfiles/archiso/syslinux/syslinux.cfg`

```
TIMEOUT 1
```

**Why**: 1 = 0.1 seconds (nearly instant).

#### Step 6.4: Auto-login and Auto-start Hyprland

**File**: `/home/galib/dotfiles/archiso/airootfs/etc/systemd/system/getty@tty1.service.d/autologin.conf`

**Current content** (should already be there):
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin root - $TERM
```

**File**: `/home/galib/dotfiles/archiso/airootfs/root/.zprofile`

**Create new file** (auto-start Hyprland after login):
```bash
# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    # Check if we're in live environment
    if grep -q "archisolabel" /proc/cmdline 2>/dev/null; then
        # Run welcome script which starts Hyprland
        exec /root/welcome.sh
    fi
fi
```

**Alternative**: Directly launch Hyprland without menu:

**File**: `/home/galib/dotfiles/archiso/airootfs/root/.zprofile`

```bash
# Auto-start Hyprland on tty1 (skip welcome menu)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    # Check if we're in live environment
    if grep -q "archisolabel" /proc/cmdline 2>/dev/null; then
        # Create liveuser and start Hyprland automatically
        /root/welcome.sh
        # Or directly: (choose one approach)
        # exec /root/auto-start-hyprland.sh
    fi
fi
```

**File**: `/home/galib/dotfiles/archiso/airootfs/root/auto-start-hyprland.sh`

**Create new file** (alternative direct start):
```bash
#!/bin/bash
#
# Auto-start Hyprland in live environment
# Skips the welcome menu for immediate boot
#

# Create liveuser if not exists
if ! id -u liveuser &>/dev/null; then
    useradd -m -G wheel,audio,video,input,seat -s /bin/zsh liveuser
    echo "liveuser:live" | chpasswd
fi

# Sync dotfiles
if [ ! -d "/home/liveuser/dotfiles" ]; then
    /root/sync-dotfiles.sh liveuser
fi

# Set up XDG_RUNTIME_DIR
LIVEUSER_UID=$(id -u liveuser)
mkdir -p /run/user/$LIVEUSER_UID
chown liveuser:liveuser /run/user/$LIVEUSER_UID
chmod 700 /run/user/$LIVEUSER_UID

# Start Hyprland
su -l liveuser << EOF
export XDG_RUNTIME_DIR=/run/user/$LIVEUSER_UID
export XDG_SESSION_TYPE=wayland
exec dbus-run-session Hyprland
EOF
```

**Set executable** in profiledef.sh.

#### Step 6.5: Remove Boot Menu Entries (Optional)

If you want only ONE boot option (no memtest, no accessibility):

**Delete or comment out**:
- `/home/galib/dotfiles/archiso/efiboot/loader/entries/02-galibos-speech-linux.conf`
- `/home/galib/dotfiles/archiso/efiboot/loader/entries/03-galibos-memtest86+x64.conf`

Or keep them for troubleshooting but they won't show with timeout=0.

---

### Phase 7: Update Installer for Galib OS

#### Step 7.1: Create Post-Install Dotfiles Setup

**File**: Update the configure.sh section in install-arch.sh (around line 262-268):

**Add after "Clone dotfiles" section**:
```bash
# Clone dotfiles
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
```

#### Step 7.2: Configure Auto-start Hyprland in Installed System

**Add to configure.sh** (after dotfiles installation):
```bash
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
```

#### Step 7.3: Install Omarchy in Target System

**Add to configure.sh** (before Hyprland installation):
```bash
# Install Omarchy base system
echo "Installing Omarchy..."

# Copy Omarchy system files from live environment
if [ -d "/usr/share/omarchy" ]; then
    cp -r /usr/share/omarchy /usr/share/
fi

# Install Omarchy package if available
# pacman -S --noconfirm omarchy || echo "Omarchy package not found, using bundled files"
```

#### Step 7.4: Configure Plymouth in Installed System

**Add to configure.sh** (after GRUB installation):
```bash
# Install and configure Plymouth
echo "Configuring Plymouth boot splash..."
pacman -S --noconfirm plymouth

# Copy Plymouth theme
if [ -d "/usr/share/plymouth/themes/galibos" ]; then
    echo "Plymouth theme already installed"
else
    # Copy from live environment
    cp -r /usr/share/plymouth/themes/galibos /usr/share/plymouth/themes/
fi

# Set Plymouth theme
plymouth-set-default-theme -R galibos

# Update mkinitcpio for Plymouth
sed -i 's/^HOOKS=.*/HOOKS=(base udev plymouth autodetect modconf block filesystems keyboard fsck)/' /etc/mkinitcpio.conf

# Rebuild initramfs
mkinitcpio -P

# Update GRUB configuration for Plymouth
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash plymouth.ignore-serial-consoles"/' /etc/default/grub

# Regenerate GRUB config
grub-mkconfig -o /boot/grub/grub.cfg
```

#### Step 7.5: Create os-release in Installed System

**Add to configure.sh**:
```bash
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

echo "galibos" > /etc/hostname

cat > /etc/issue << 'EOF'
Galib OS \r (\l)
EOF
```

---

### Phase 8: Testing

#### Step 8.1: Pre-build Checklist

Before building the ISO, verify:

**Dotfiles Sync**:
```bash
# Ensure all dotfiles are synced to airootfs
cd /home/galib/dotfiles
rsync -av --dry-run --exclude='.git' --exclude='hyprland/' \
    ./ archiso/airootfs/root/dotfiles/

# If looks good, remove --dry-run
rsync -av --exclude='.git' --exclude='hyprland/' \
    ./ archiso/airootfs/root/dotfiles/
```

**Omarchy Files**:
```bash
# Verify Omarchy files are present
ls -la /home/galib/dotfiles/archiso/airootfs/root/dotfiles/omarchy/
ls -la /home/galib/dotfiles/archiso/airootfs/root/dotfiles/omarchy/usr/share/plymouth/themes/omarchy/
```

**Script Permissions**:
```bash
# Check scripts are executable
ls -la /home/galib/dotfiles/archiso/airootfs/root/*.sh
```

**Package List**:
```bash
# Verify no KDE packages
grep -i plasma /home/galib/dotfiles/archiso/packages.x86_64
grep -i sddm /home/galib/dotfiles/archiso/packages.x86_64
# Should return nothing

# Verify Hyprland packages
grep -i hyprland /home/galib/dotfiles/archiso/packages.x86_64
```

#### Step 8.2: Build the ISO

**Create build directory**:
```bash
# Create a working directory outside dotfiles
mkdir -p ~/iso-build
cd ~/iso-build

# Copy archiso profile
cp -r /home/galib/dotfiles/archiso/* ./

# Verify structure
tree -L 2
```

**Build**:
```bash
# Build the ISO (requires root)
sudo mkarchiso -v -w /tmp/archiso-tmp ./

# This will create the ISO in ./out/
# Expected output: galibos-YYYY.MM.DD-x86_64.iso
```

**Build time**: Approximately 15-30 minutes depending on internet speed and system.

#### Step 8.3: Test in Virtual Machine

**Using QEMU**:
```bash
# Basic test (UEFI)
sudo pacman -S qemu-full edk2-ovmf

# Run VM with 4GB RAM
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -smp 2 \
    -bios /usr/share/edk2/x64/OVMF.fd \
    -cdrom ./out/galibos-*.iso \
    -boot d \
    -vga virtio \
    -display gtk,gl=on
```

**Using VirtualBox**:
```bash
# Create new VM
- Name: Galib OS Test
- Type: Linux
- Version: Arch Linux (64-bit)
- RAM: 4096 MB
- Hard Disk: 20 GB (for installation test)

# Settings:
- System → Enable EFI
- Display → Video Memory: 128 MB
- Storage → Add galibos-*.iso as optical drive

# Boot and test
```

**Using Ventoy** (real hardware test):
```bash
# Install Ventoy on USB drive
# Copy galibos-*.iso to Ventoy drive
# Boot from USB on real hardware
```

#### Step 8.4: Testing Checklist

**Live Environment Test**:
- [ ] ISO boots without errors
- [ ] Plymouth splash screen shows "Galib OS"
- [ ] No boot menu appears (auto-boot)
- [ ] Hyprland starts automatically
- [ ] No "Arch Linux" or "Omarchy" references in UI
- [ ] Dotfiles are accessible at ~/dotfiles/
- [ ] Terminal emulators work (Alacritty, Kitty)
- [ ] Neofetch/Fastfetch shows "Galib OS"
- [ ] Network connectivity works (WiFi/Ethernet)
- [ ] Welcome script accessible (if needed)

**Installer Test**:
- [ ] Installer launches without errors
- [ ] Disk partitioning works correctly
- [ ] Base system installs successfully
- [ ] Hyprland installs (no KDE)
- [ ] Dotfiles copy to installed system
- [ ] Plymouth installs and configures
- [ ] GRUB installs and configures correctly
- [ ] System reboots successfully

**Installed System Test**:
- [ ] System boots with Plymouth "Galib OS" splash
- [ ] Auto-login works
- [ ] Hyprland starts automatically
- [ ] Dotfiles are stowed correctly
- [ ] Zsh is default shell with P10k theme
- [ ] Neovim works with plugins
- [ ] Tmux configuration loads
- [ ] All terminal emulators work
- [ ] VS Code launches
- [ ] Network connectivity maintained
- [ ] System identifies as "Galib OS" in neofetch

#### Step 8.5: Debugging Common Issues

**Issue: ISO won't boot**
```bash
# Check ISO integrity
sha256sum ./out/galibos-*.iso

# Verify ISO structure
sudo mount -o loop ./out/galibos-*.iso /mnt
ls -la /mnt
sudo umount /mnt
```

**Issue: Plymouth doesn't show**
```bash
# In live environment, check Plymouth
plymouth-set-default-theme --list
plymouth-set-default-theme

# Rebuild initramfs
sudo mkinitcpio -P
```

**Issue: Hyprland won't start**
```bash
# Check logs
journalctl -xe

# Test Hyprland manually
Hyprland

# Check if all dependencies installed
pacman -Q | grep -i hypr
```

**Issue: Dotfiles not found**
```bash
# Verify in airootfs before build
ls -la /home/galib/dotfiles/archiso/airootfs/root/dotfiles/

# Check after boot in live environment
ls -la /root/dotfiles/
```

**Issue: "Omarchy" or "Arch Linux" still visible**
```bash
# Search for remaining references
grep -r "Omarchy" /home/galib/dotfiles/archiso/ 2>/dev/null
grep -r "Arch Linux" /home/galib/dotfiles/archiso/ 2>/dev/null

# Exclude expected locations (like package names)
```

---

## File Modifications Reference

This section provides a complete before/after for all modified files.

### profiledef.sh

**Location**: `/home/galib/dotfiles/archiso/profiledef.sh`

**Changes**:
```diff
-iso_name="custom-arch"
-iso_label="CUSTOMARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
-iso_publisher="Custom Arch Linux with Dotfiles"
-iso_application="Custom Arch Linux Live/Install Environment"
+iso_name="galibos"
+iso_label="GALIBOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
+iso_publisher="Galib OS - Arch Linux with Omarchy and Custom Dotfiles"
+iso_application="Galib OS Live/Install Environment"

 file_permissions=(
   ["/etc/shadow"]="0:0:400"
   ["/root"]="0:0:750"
   ["/root/.automated_script.sh"]="0:0:755"
   ["/root/.gnupg"]="0:0:700"
   ["/root/install-arch.sh"]="0:0:755"
   ["/root/welcome.sh"]="0:0:755"
+  ["/root/setup-omarchy.sh"]="0:0:755"
+  ["/root/sync-dotfiles.sh"]="0:0:755"
+  ["/root/auto-start-hyprland.sh"]="0:0:755"
   ["/root/dotfiles/install.sh"]="0:0:755"
   ["/root/dotfiles/stowup"]="0:0:755"
   ["/root/dotfiles/stowDown"]="0:0:755"
   ["/usr/local/bin/choose-mirror"]="0:0:755"
   ["/usr/local/bin/Installation_guide"]="0:0:755"
   ["/usr/local/bin/livecd-sound"]="0:0:755"
 )
```

### packages.x86_64

**Location**: `/home/galib/dotfiles/archiso/packages.x86_64`

**Changes**:
```diff
 mkinitcpio
 mkinitcpio-archiso
 mkinitcpio-nfs-utils
+plymouth
 mtools

... (keep base packages)

-# KDE Plasma Desktop Environment
-plasma-desktop
-plasma-nm
-plasma-pa
-plasma-workspace
-kscreen
-powerdevil
-sddm
-konsole
-dolphin
-kate
-ark
-spectacle
-gwenview
-okular

 # Hyprland and Wayland components
 hyprland
 waybar
 wofi
+rofi
 dunst
+mako
 grim
 slurp
 wl-clipboard
 xdg-desktop-portal-hyprland
 xdg-desktop-portal-gtk
+polkit-kde-agent
 qt5-wayland
 qt6-wayland
+qt5ct
+kvantum

... (keep rest of packages)

+# Terminal emulators
+alacritty
+kitty
+wezterm
+# ghostty  # Add if available in repos
+
+# Additional CLI tools
+lazygit
+lazydocker
+delta
+procs
+bottom
+tokei
+hyperfine
```

### welcome.sh

**Location**: `/home/galib/dotfiles/archiso/airootfs/root/welcome.sh`

**Changes**: See Phase 4, Step 4.6 for complete updated file.

Key changes:
- Banner changed to "Galib OS"
- Removed KDE option (option 1)
- Renumbered options
- Updated to use sync-dotfiles.sh

### install-arch.sh

**Location**: `/home/galib/dotfiles/archiso/airootfs/root/install-arch.sh`

**Changes**: See Phase 4, Step 4.7 for details.

Key changes:
- Banner changed to "Galib OS"
- Removed KDE installation option
- Updated configure.sh to install only Hyprland
- Added Omarchy setup
- Added Plymouth configuration
- Added os-release creation

### /etc/os-release

**Location**: `/home/galib/dotfiles/archiso/airootfs/etc/os-release`

**New file** (see Phase 4, Step 4.2)

### /etc/hostname

**Location**: `/home/galib/dotfiles/archiso/airootfs/etc/hostname`

**Changes**:
```diff
-archiso
+galibos
```

### /etc/motd

**Location**: `/home/galib/dotfiles/archiso/airootfs/etc/motd`

**Changes**: See Phase 4, Step 4.5 for complete new content.

### Boot Loader Files

**systemd-boot loader.conf**:
```diff
-timeout 3
-default 01-archiso-linux.conf
+timeout 0
+default 01-galibos-linux.conf
+console-mode max
+editor no
```

**Rename**:
- `01-archiso-linux.conf` → `01-galibos-linux.conf`

**Update entry**:
```diff
-title   Arch Linux
+title   Galib OS
 linux   /%INSTALL_DIR%/boot/x86_64/vmlinuz-linux
 initrd  /%INSTALL_DIR%/boot/x86_64/initramfs-linux.img
-options archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL%
+options archisobasedir=%INSTALL_DIR% archisolabel=%ARCHISO_LABEL% quiet splash plymouth.ignore-serial-consoles
```

---

## Complete Package List

Final package list for Galib OS ISO:

### Base System (Essential)
```
# Core
base
base-devel
linux
linux-firmware
linux-firmware-marvell

# Boot
grub
efibootmgr
mkinitcpio
mkinitcpio-archiso
mkinitcpio-nfs-utils
plymouth
syslinux

# Microcode
amd-ucode
intel-ucode

# System utilities
sudo
systemd-resolvconf
```

### Networking
```
networkmanager
network-manager-applet
iw
iwd
wpa_supplicant
openssh
dnsmasq
bind
dhcpcd
```

### File Systems
```
btrfs-progs
bcachefs-tools
dosfstools
e2fsprogs
exfatprogs
f2fs-tools
ntfs-3g
xfsprogs
jfsutils

gvfs
gvfs-mtp
gvfs-afc
gvfs-gphoto2
gvfs-smb
gvfs-nfs
```

### Development Tools
```
git
stow
neovim
tmux
wget
curl
unzip
zip
tar
gzip
which
```

### Shell & Terminal
```
zsh
alacritty
kitty
wezterm
# ghostty (if available)
```

### Hyprland Desktop
```
hyprland
waybar
wofi
rofi
dunst
mako
grim
slurp
wl-clipboard
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
polkit-kde-agent
qt5-wayland
qt6-wayland
qt5ct
kvantum
swaylock
swayidle
```

### X11 Support
```
xorg-server
xorg-xinit
xorg-xwayland
```

### Audio
```
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
wireplumber
alsa-utils
```

### Bluetooth
```
bluez
bluez-utils
blueberry
```

### Fonts
```
ttf-jetbrains-mono-nerd
ttf-liberation
ttf-dejavu
noto-fonts
noto-fonts-emoji
terminus-font
```

### CLI Utilities
```
bat
eza
fd
ripgrep
fzf
zoxide
starship
fastfetch
btop
htop
tree
duf
dust
lazygit
lazydocker
delta
procs
bottom
tokei
hyperfine
```

### Archive Tools
```
p7zip
unrar
```

### System Utilities
```
brightnessctl
acpi
acpid
cpupower
rsync
reflector
```

### Applications
```
firefox
# zen-browser (if available)
```

### Installation Tools
```
arch-install-scripts
archinstall
parted
gpart
gptfdisk
vim
nano
screen
```

**Total packages**: ~150-180 packages
**Expected ISO size**: ~2-3 GB

---

## Build & Test Commands

### Complete Build Process

#### Step 1: Prepare Build Environment
```bash
# Install archiso
sudo pacman -S archiso

# Create build directory
mkdir -p ~/galib-os-build
cd ~/galib-os-build
```

#### Step 2: Sync Dotfiles to airootfs
```bash
# Navigate to dotfiles
cd /home/galib/dotfiles

# Sync all packages except hyprland to airootfs
rsync -av --delete \
    --exclude='.git' \
    --exclude='hyprland/' \
    --exclude='archiso/out' \
    --exclude='archiso/work' \
    ./ archiso/airootfs/root/dotfiles/

# Verify sync
ls -la archiso/airootfs/root/dotfiles/
```

#### Step 3: Copy archiso Profile to Build Directory
```bash
# Copy entire archiso profile
cp -r /home/galib/dotfiles/archiso ~/galib-os-build/galibos

cd ~/galib-os-build/galibos
```

#### Step 4: Final Pre-build Checks
```bash
# Verify package list (no KDE)
grep -i "plasma\|sddm\|kde" packages.x86_64
# Should return nothing

# Verify scripts are present
ls -la airootfs/root/*.sh

# Verify profiledef.sh
cat profiledef.sh | grep iso_name
# Should show: iso_name="galibos"

# Check dotfiles are synced
ls -la airootfs/root/dotfiles/
```

#### Step 5: Build ISO
```bash
# Build (this will take 15-30 minutes)
sudo mkarchiso -v -w /tmp/galibos-work -o ./out ./

# Monitor build progress
# The build process will:
# 1. Download all packages
# 2. Install to work directory
# 3. Apply airootfs overlay
# 4. Create squashfs
# 5. Generate ISO
```

#### Step 6: Verify Build
```bash
# Check output
ls -lh out/

# Expected output:
# galibos-YYYY.MM.DD-x86_64.iso (2-3 GB)

# Verify ISO integrity
sha256sum out/galibos-*.iso > out/galibos-*.iso.sha256
```

#### Step 7: Test in VM
```bash
# QEMU test (quick)
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -bios /usr/share/edk2/x64/OVMF.fd \
    -cdrom out/galibos-*.iso \
    -boot d \
    -vga virtio \
    -display gtk,gl=on \
    -cpu host
```

### Incremental Build (After Changes)

If you make changes to airootfs only (no package changes):

```bash
# Clean work directory but keep package cache
sudo rm -rf /tmp/galibos-work

# Rebuild
sudo mkarchiso -v -w /tmp/galibos-work -o ./out ./
```

### Complete Rebuild (Full Clean)

```bash
# Remove everything
sudo rm -rf /tmp/galibos-work
rm -rf out/

# Rebuild from scratch
sudo mkarchiso -v -w /tmp/galibos-work -o ./out ./
```

### Testing Matrix

**Environments to test**:
1. QEMU/KVM (UEFI)
2. VirtualBox (UEFI + BIOS)
3. Real hardware (if available)
4. Ventoy USB boot (real hardware)

**Test scenarios**:
1. Live boot only
2. Live boot + installation
3. Installation without live session
4. Network connectivity (WiFi + Ethernet)
5. Plymouth splash screen
6. Hyprland functionality
7. Dotfiles installation

---

## Troubleshooting Guide

### Build Issues

#### Issue: Package not found
```
Error: package 'somepackage' was not found
```

**Solution**:
```bash
# Check if package exists
pacman -Ss somepackage

# If not found, remove from packages.x86_64 or find alternative

# Update mirrorlist
sudo reflector --country US --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Try build again
```

#### Issue: Out of disk space
```
Error: not enough free disk space
```

**Solution**:
```bash
# Check disk space
df -h /tmp

# Clean package cache
sudo pacman -Scc

# Use different work directory
sudo mkarchiso -v -w /path/to/larger/partition/work -o ./out ./
```

#### Issue: Permission denied
```
Error: permission denied
```

**Solution**:
```bash
# Ensure running with sudo
sudo mkarchiso ...

# Check file ownership
ls -la airootfs/root/

# Fix ownership if needed
sudo chown -R $USER:$USER ~/galib-os-build/
```

### Boot Issues

#### Issue: ISO won't boot in VM
```
No bootable device found
```

**Solution**:
```bash
# Verify ISO integrity
sha256sum out/galibos-*.iso

# Check ISO is properly mounted in VM

# For QEMU, ensure UEFI firmware:
qemu-system-x86_64 -bios /usr/share/edk2/x64/OVMF.fd ...

# For VirtualBox, enable EFI in settings
```

#### Issue: Stuck at boot menu
```
Boot menu appears but won't proceed
```

**Solution**:
```bash
# Check bootloader timeout settings
cat efiboot/loader/loader.conf
# Should be: timeout 0

# Rebuild ISO after fixing
```

#### Issue: Plymouth doesn't show
```
No boot splash, just black screen with text
```

**Solution**:
```bash
# In live environment, check:
plymouth-set-default-theme

# Verify kernel parameters have "splash"
cat /proc/cmdline

# Check if Plymouth is in initramfs
lsinitcpio /boot/initramfs-linux.img | grep plymouth
```

### Live Environment Issues

#### Issue: Hyprland won't start
```
Hyprland failed to start
```

**Solution**:
```bash
# Check logs
journalctl -xe
journalctl -b | grep -i hypr

# Verify graphics drivers loaded
lsmod | grep -i drm

# Test manually
Hyprland

# Check if all dependencies installed
pacman -Q | grep hyprland
```

#### Issue: Dotfiles missing
```
/root/dotfiles not found
```

**Solution**:
```bash
# Verify in build
ls -la ~/galib-os-build/galibos/airootfs/root/dotfiles/

# If missing, sync again before build:
rsync -av /home/galib/dotfiles/ \
    ~/galib-os-build/galibos/airootfs/root/dotfiles/ \
    --exclude='.git' --exclude='hyprland/' --exclude='archiso/'
```

#### Issue: Network not working
```
No internet connectivity
```

**Solution**:
```bash
# Check network status
ip link
ip addr

# Start NetworkManager
sudo systemctl start NetworkManager

# For WiFi
nmcli device wifi list
nmcli device wifi connect SSID password PASSWORD

# Or use iwctl
iwctl
> station wlan0 scan
> station wlan0 get-networks
> station wlan0 connect SSID
```

### Installation Issues

#### Issue: Installer fails at partitioning
```
Error: partition creation failed
```

**Solution**:
```bash
# Check disk
lsblk
sudo fdisk -l

# Manually partition first
sudo cfdisk /dev/sdX

# Then run installer
```

#### Issue: pacstrap fails
```
Error: failed to install packages
```

**Solution**:
```bash
# Update mirrorlist
sudo reflector --country US --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Check internet
ping archlinux.org

# Try manual pacstrap
pacstrap /mnt base linux linux-firmware
```

#### Issue: GRUB installation fails
```
Error: failed to install GRUB
```

**Solution**:
```bash
# Verify EFI mode
ls /sys/firmware/efi/efivars

# Check EFI partition mounted
mount | grep /mnt/boot

# Manual GRUB install
arch-chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
```

### Post-Installation Issues

#### Issue: System won't boot after install
```
Grub menu shows but won't boot
```

**Solution**:
```bash
# Boot from live ISO
# Mount partitions
mount /dev/sdXn /mnt
mount /dev/sdX1 /mnt/boot

# Chroot
arch-chroot /mnt

# Reinstall GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Update initramfs
mkinitcpio -P
```

#### Issue: Auto-login not working
```
Login prompt appears instead of auto-login
```

**Solution**:
```bash
# Check getty service
systemctl status getty@tty1

# Verify autologin config
cat /etc/systemd/system/getty@tty1.service.d/autologin.conf

# Recreate if needed
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin yourusername - \$TERM
EOF

sudo systemctl daemon-reload
```

#### Issue: Dotfiles not working
```
Dotfiles not stowed or not working
```

**Solution**:
```bash
# Check dotfiles exist
ls -la ~/dotfiles/

# Try manual stow
cd ~/dotfiles
./stowup omarchy
./stowup zsh
./stowup nvim
# etc.

# Check for conflicts
stow -t ~ -n -v omarchy  # dry run

# If conflicts, remove old files first
```

### Branding Issues

#### Issue: Still seeing "Arch Linux" or "Omarchy"
```
Neofetch shows "Arch Linux"
```

**Solution**:
```bash
# Check os-release
cat /etc/os-release
# Should show "Galib OS"

# If not, create it:
sudo tee /etc/os-release << EOF
NAME="Galib OS"
PRETTY_NAME="Galib OS"
ID=galibos
ID_LIKE=arch
BUILD_ID=rolling
EOF

# Clear neofetch cache
rm -rf ~/.cache/neofetch
neofetch
```

#### Issue: Wrong boot splash
```
Plymouth shows wrong theme
```

**Solution**:
```bash
# List themes
plymouth-set-default-theme --list

# Set correct theme
sudo plymouth-set-default-theme -R galibos

# Rebuild initramfs
sudo mkinitcpio -P

# Reboot to test
```

### Performance Issues

#### Issue: ISO is too large
```
ISO exceeds 4GB
```

**Solution**:
```bash
# Remove unnecessary packages from packages.x86_64
# Consider removing:
# - Extra fonts
# - Documentation packages
# - Optional language packs

# Use better compression in profiledef.sh
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
```

#### Issue: Slow boot
```
System takes too long to boot
```

**Solution**:
```bash
# Check systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain

# Disable slow services
sudo systemctl disable slow-service.service

# Optimize mkinitcpio HOOKS
# Remove unnecessary hooks
```

---

## Additional Resources

### Useful Commands

**Check ISO contents**:
```bash
sudo mount -o loop galibos-*.iso /mnt
tree -L 3 /mnt
sudo umount /mnt
```

**Extract squashfs**:
```bash
sudo unsquashfs /mnt/arch/x86_64/airootfs.sfs
```

**Test Plymouth theme**:
```bash
sudo plymouthd
sudo plymouth --show-splash
# Wait a few seconds
sudo plymouth quit
```

**Monitor build**:
```bash
# In another terminal
watch -n 1 'df -h /tmp/galibos-work'
```

### Links

- Archiso documentation: https://wiki.archlinux.org/title/Archiso
- Plymouth themes: https://wiki.archlinux.org/title/Plymouth
- Hyprland wiki: https://wiki.hyprland.org
- Omarchy: https://github.com/omarchy/omarchy

### File Structure Summary

```
/home/galib/dotfiles/archiso/
├── packages.x86_64              # Package list (KDE removed, Hyprland enhanced)
├── profiledef.sh                # ISO metadata (branded as Galib OS)
├── pacman.conf                  # Pacman configuration
├── bootstrap_packages           # Bootstrap packages
│
├── airootfs/                    # Root filesystem overlay
│   ├── etc/
│   │   ├── os-release          # NEW: Galib OS identification
│   │   ├── hostname            # CHANGED: galibos
│   │   ├── issue               # CHANGED: Galib OS
│   │   ├── motd                # CHANGED: Galib OS welcome
│   │   ├── plymouth/
│   │   │   └── plymouthd.conf  # NEW: Plymouth config
│   │   ├── mkinitcpio.conf.d/
│   │   │   └── plymouth.conf   # NEW: Plymouth in initramfs
│   │   └── skel/
│   │       ├── .zshrc          # NEW: Basic zsh config
│   │       └── .config/
│   │           └── fastfetch/
│   │               └── config.jsonc  # NEW: Galib OS fastfetch
│   │
│   ├── root/
│   │   ├── .zprofile           # NEW: Auto-start Hyprland
│   │   ├── welcome.sh          # CHANGED: Galib OS branding, no KDE
│   │   ├── install-arch.sh     # CHANGED: Galib OS install, no KDE
│   │   ├── setup-omarchy.sh    # NEW: Omarchy setup
│   │   ├── sync-dotfiles.sh    # NEW: Dotfiles sync
│   │   ├── auto-start-hyprland.sh  # NEW: Auto-start script
│   │   └── dotfiles/           # Your complete dotfiles (synced)
│   │       ├── omarchy/        # Omarchy configs
│   │       ├── zsh/
│   │       ├── nvim/
│   │       └── ... (all except hyprland/)
│   │
│   └── usr/
│       ├── share/
│       │   ├── galibos/
│       │   │   └── about.txt   # NEW: Galib OS info
│       │   └── plymouth/themes/galibos/  # NEW: Plymouth theme
│       │       ├── galibos.plymouth
│       │       ├── galibos.script
│       │       └── logo.png
│       └── local/bin/
│
├── efiboot/
│   └── loader/
│       ├── loader.conf         # CHANGED: timeout 0
│       └── entries/
│           └── 01-galibos-linux.conf  # RENAMED & CHANGED
│
├── grub/
│   └── grub.cfg                # CHANGED: Galib OS, timeout 0
│
└── syslinux/
    └── syslinux.cfg            # CHANGED: Galib OS, timeout 1
```

---

## Summary

This implementation plan provides a complete roadmap for building Galib OS. The key points:

1. **Removes KDE entirely** - Hyprland only, reducing ISO size
2. **Bundles Omarchy** - Pre-configured Hyprland environment
3. **Includes all dotfiles** - Except hyprland/ directory as requested
4. **Complete branding** - All references changed to "Galib OS"
5. **Auto-boot** - No menu, straight to Hyprland
6. **Plymouth splash** - Branded boot screen
7. **Automated installer** - Installs configured system

**Estimated timeline**:
- Implementation: 4-6 hours
- Testing: 2-3 hours
- Refinement: 2-4 hours
- **Total**: 8-13 hours

**Next steps**:
1. Review this plan
2. Make any adjustments needed
3. Follow Phase 1 to start implementation
4. Build and test iteratively
5. Refine based on testing results

Good luck building Galib OS!
