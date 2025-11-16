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