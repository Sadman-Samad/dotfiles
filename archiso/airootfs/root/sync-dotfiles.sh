#!/bin/bash
#
# Sync dotfiles to Galib OS
# This script prepares all dotfiles packages except the old hyprland/
#

set -e

echo "[Galib OS] Syncing dotfiles..."

DOTFILES_DIR="/root/dotfiles"
TARGET_USER="$1"
if [ -z "$TARGET_USER" ]; then
    TARGET_USER="root"
fi

TARGET_HOME="/home/$TARGET_USER"
if [ "$TARGET_USER" = "root" ]; then
    TARGET_HOME="/root"
fi

# Create target directories
mkdir -p "$TARGET_HOME/.local/share/omarchy"
mkdir -p "$TARGET_HOME/.config"
mkdir -p "$TARGET_HOME/.local/bin"

# Function to safely copy dotfiles package
copy_package() {
    local package="$1"
    local source_dir="$DOTFILES_DIR/$package"
    local target_dir="$TARGET_HOME"

    if [ ! -d "$source_dir" ]; then
        echo "[Galib OS] Package $package not found, skipping..."
        return
    fi

    echo "[Galib OS] Copying package: $package"

    if [ "$package" = "bin" ]; then
        cp -r "$source_dir"/* "$TARGET_HOME/.local/bin/" 2>/dev/null || true
    elif [ "$package" = "boot" ]; then
        # Skip boot package - it's system-level
        echo "[Galib OS] Skipping boot package (system-level)"
    elif [ "$package" = "obsidian" ]; then
        # Handle obsidian specially - only copy config, not vaults
        if [ -d "$source_dir/.obsidian" ]; then
            mkdir -p "$TARGET_HOME/.config/obsidian"
            cp -r "$source_dir/.obsidian" "$TARGET_HOME/.config/"
        fi
    else
        cp -r "$source_dir" "$target_dir/"
    fi

    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/$package" 2>/dev/null || true
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin" 2>/dev/null || true
}

# List of packages to include (exclude old hyprland)
PACKAGES=(
    "alacritty"
    "bin"
    "claude-code"
    "ghostty"
    "kitty"
    "nvim"
    "obsidian"
    "omarchy"
    "p10k"
    "tmux"
    "vscode"
    "waybar"
    "wezterm"
    "zen-browser"
    "zsh"
)

# Copy all packages
for package in "${PACKAGES[@]}"; do
    copy_package "$package"
done

# Create deploy-dotfiles script for the user
cat > "$TARGET_HOME/.local/bin/deploy-dotfiles" << 'EOF'
#!/bin/bash
# Deploy dotfiles using GNU Stow

cd ~/dotfiles

# Install packages in proper order
./stowup zsh       # Shell first
./stowup p10k      # Theme
./stowup tmux      # Terminal multiplexer
./stowup nvim      # Editor
./stowup omarchy   # Omarchy overrides
./stowup waybar    # Status bar

# Install terminal emulators (user choice)
if command -v alacritty >/dev/null 2>&1; then
    ./stowup alacritty
fi

if command -v kitty >/dev/null 2>&1; then
    ./stowup kitty
fi

if command -v ghostty >/dev/null 2>&1; then
    ./stowup ghostty
fi

if command -v wezterm >/dev/null 2>&1; then
    ./stowup wezterm
fi

echo "[Galib OS] Dotfiles deployed successfully!"
echo "[Galib OS] Restart your shell or log out and back in to see changes."
EOF

chmod +x "$TARGET_HOME/.local/bin/deploy-dotfiles"

# Set proper ownership
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/deploy-dotfiles"

# Configure zsh as default shell if not root
if [ "$TARGET_USER" != "root" ]; then
    chsh -s /bin/zsh "$TARGET_USER"
    echo "[Galib OS] Set zsh as default shell for $TARGET_USER"
fi

echo "[Galib OS] Dotfiles sync completed for $TARGET_USER!"
echo "[Galib OS] Run 'deploy-dotfiles' to apply configurations"