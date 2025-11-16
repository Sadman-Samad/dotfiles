#!/bin/bash
#
# Setup Omarchy for Galib OS
# This script bundles Omarchy configuration and scripts in the ISO
#

set -e

echo "[Galib OS] Setting up Omarchy configuration..."

# Create necessary directories
mkdir -p /usr/local/share/omarchy/default
mkdir -p /usr/local/bin
mkdir -p /usr/share/plymouth/themes/galib-os

# If we have a local clone of Omarchy, sync it
if [ -d "/tmp/omarchy-source" ]; then
    echo "[Galib OS] Syncing Omarchy defaults from local source..."
    rsync -av /tmp/omarchy-source/.local/share/omarchy/ /usr/local/share/omarchy/

    # Install Omarchy scripts to /usr/local/bin
    if [ -d "/tmp/omarchy-source/.local/bin" ]; then
        rsync -av /tmp/omarchy-source/.local/bin/ /usr/local/bin/
        chmod +x /usr/local/bin/omarchy-*
        echo "[Galib OS] Installed Omarchy scripts to /usr/local/bin/"
    fi
else
    # If no local source, create essential directories and basic scripts
    echo "[Galib OS] No local Omarchy source found, creating basic structure..."

    # Create default Hyprland config directory
    mkdir -p /usr/local/share/omarchy/default/hypr

    # Create essential basic configurations
    cat > /usr/local/share/omarchy/default/hypr/autostart.conf << 'EOF'
# Omarchy autostart - Basic version for Galib OS
exec-once = uwsm start -- gtk-launch
exec-once = waybar
exec-once = dunst
EOF

    cat > /usr/local/share/omarchy/default/hypr/bindings/utilities.conf << 'EOF'
# Omarchy utility bindings - Basic version for Galib OS
bindl = SUPER, Print, exec, grim - | wl-copy
bindl = SUPER SHIFT, Print, exec, grim -g "$(slurp)" - | wl-copy
bindl = SUPER, Q, killactive
bindl = SUPER SHIFT, Q, exit
EOF

    # Create placeholder scripts if Omarchy source isn't available
    for script in omarchy-launch-browser omarchy-launch-editor omarchy-launch-terminal; do
        cat > "/usr/local/bin/$script" << EOF
#!/bin/bash
# Placeholder $script for Galib OS
case "\$script" in
    *browser*) exec firefox & ;;
    *editor*) exec nvim & ;;
    *terminal*) exec alacritty & ;;
esac
EOF
        chmod +x "/usr/local/bin/$script"
    done
fi

# Set up Plymouth theme
if [ -d "/root/dotfiles/omarchy/usr/share/plymouth/themes/omarchy" ]; then
    echo "[Galib OS] Installing Plymouth theme..."
    cp -r /root/dotfiles/omarchy/usr/share/plymouth/themes/omarchy /usr/share/plymouth/themes/galib-os
    chown -R root:root /usr/share/plymouth/themes/galib-os

    # Update theme references
    sed -i 's/omarchy/galib-os/g' /usr/share/plymouth/themes/galib-os/omarchy.plymouth
    mv /usr/share/plymouth/themes/galib-os/omarchy.plymouth /usr/share/plymouth/themes/galib-os/galib-os.plymouth
    mv /usr/share/plymouth/themes/galib-os/omarchy.script /usr/share/plymouth/themes/galib-os/galib-os.script

    # Set Plymouth theme
    plymouth-set-default-theme -R galib-os || echo "Plymouth theme will be set during boot"
fi

# Create Galib OS branding files
mkdir -p /usr/lib/galib-os

echo "[Galib OS] Omarchy setup completed successfully!"
echo "[Galib OS] Ready to deploy Galib OS with Omarchy base"