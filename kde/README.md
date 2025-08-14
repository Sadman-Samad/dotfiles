# KDE Plasma + Krohnkite Configuration

This package contains KDE Plasma desktop environment configuration files, including Krohnkite tiling window manager settings.

## Setup Instructions

### Quick Setup (Recommended)
**Capture your current configuration:**
```bash
# Capture and sync your current KDE setup
bin/sync-kde-config --commit

# This will:
# 1. Capture your current KDE configuration 
# 2. Create shortcuts preset from your current setup
# 3. Commit changes to git for future deployments
```

### Manual Setup

### 1. Install Krohnkite
Install Krohnkite from AUR:
```bash
yay -S kwin-scripts-krohnkite-git
# or
paru -S kwin-scripts-krohnkite-git
```

### 2. Capture Current Configuration (Important!)
Before using the template configs, capture your current setup:
```bash
# Capture your current KDE configuration
bin/capture-kde-config

# Or just shortcuts if you only want those
bin/capture-kde-config --shortcuts-only
```

### 3. Apply Configuration
```bash
# From dotfiles root directory
stow kde
```

### 4. Enable Krohnkite
After applying the configuration, you need to:

1. **Create required symlink for user configuration:**
   ```bash
   mkdir -p ~/.local/share/kservices5/
   ln -s ~/.local/share/kwin/scripts/krohnkite/metadata.desktop ~/.local/share/kservices5/krohnkite.desktop
   ```

2. **Restart KWin to apply changes:**
   ```bash
   kwin_x11 --replace & disown  # For X11
   # or
   kwin_wayland --replace & disown  # For Wayland
   ```

3. **Or restart KWin service:**
   ```bash
   qdbus org.kde.KWin /KWin reconfigure
   ```

### 4. Verify Installation
- Open System Settings → Window Management → KWin Scripts
- Ensure Krohnkite is enabled
- Check keyboard shortcuts in System Settings → Shortcuts → Global Shortcuts → KWin

## Configuration Files Included

- `kwinrc` - Main KWin configuration with Krohnkite settings
- `kglobalshortcutsrc` - Global keyboard shortcuts including Krohnkite shortcuts
- `kwinrulesrc` - Window rules for specific applications
- `plasma-org.kde.plasma.desktop-appletsrc` - Plasma desktop layout and widgets
- `krunnerrc` - KRunner (application launcher) configuration

## Customization

### Configuration Management

**Automated Configuration Capture:**
```bash
# Capture your current KDE setup (recommended)
bin/capture-kde-config --backup-first

# Test the captured configuration
bin/capture-kde-config --dry-run

# Capture only shortcuts (faster)
bin/capture-kde-config --shortcuts-only
```

**Manual Configuration Replacement:**
If you prefer manual copying, replace template files with your actual configuration:
```bash
# Backup current configs first
cp ~/.config/kwinrc ~/kwinrc.backup
cp ~/.config/kglobalshortcutsrc ~/kglobalshortcutsrc.backup

# Copy your actual configs to dotfiles (use capture script instead!)
cp ~/.config/kwinrc ./kde/.config/
cp ~/.config/kglobalshortcutsrc ./kde/.config/
cp ~/.config/kwinrulesrc ./kde/.config/
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc ./kde/.config/
cp ~/.config/krunnerrc ./kde/.config/
```

### Krohnkite Default Shortcuts
- `Meta+F` - Toggle tiling for current window
- `Meta+Shift+F` - Toggle floating for current window
- `Meta+Return` - Set window as master
- `Meta+J/K` - Move focus between windows
- `Meta+Shift+J/K` - Move windows
- `Meta+H/L` - Resize master area
- `Meta+\\` - Switch to next layout
- `Meta+R` - Rotate windows

## Shortcut Management

### Command-Line Shortcut Management
Use the `kde-shortcuts` script for programmatic shortcut control:

```bash
# List all shortcuts
bin/kde-shortcuts list

# List KWin shortcuts only  
bin/kde-shortcuts list kwin

# Set a shortcut
bin/kde-shortcuts set kwin "Window Close" "Alt+Q"

# Get current shortcut
bin/kde-shortcuts get kwin "Window Close"

# Remove/disable a shortcut
bin/kde-shortcuts remove kwin "Overview"

# Backup shortcuts
bin/kde-shortcuts backup ~/my-shortcuts-backup.conf

# Restore from backup
bin/kde-shortcuts restore ~/my-shortcuts-backup.conf

# Show Krohnkite-specific shortcuts
bin/kde-shortcuts krohnkite

# Reload configuration
bin/kde-shortcuts reload
```

### Shortcut Presets
Apply predefined shortcut configurations:

```bash
# List available presets
bin/apply-shortcuts-preset --list

# Apply a preset with backup
bin/apply-shortcuts-preset krohnkite-default --backup

# Preview changes without applying  
bin/apply-shortcuts-preset developer-focused --dry-run

# Available presets:
# - krohnkite-default: Standard Krohnkite tiling shortcuts
# - krohnkite-vim: Vim-style Krohnkite shortcuts
# - developer-focused: Optimized for coding workflow
# - gaming-minimal: Minimal shortcuts to avoid game conflicts
# - accessibility: Larger, easier-to-reach shortcuts
# - vim-navigation: Vi-style navigation system-wide
```

### Preset Configuration
Customize presets by editing `kde/shortcuts-presets.conf`. Each preset section defines shortcuts in `action=key` format.

## Troubleshooting

### Krohnkite Not Working
1. Ensure the symlink is created correctly
2. Check if Krohnkite is enabled in System Settings → Window Management → KWin Scripts
3. Restart KWin: `qdbus org.kde.KWin /KWin reconfigure`

### Shortcuts Not Working
1. Use `bin/kde-shortcuts list kwin` to check current shortcuts
2. Look for conflicts: `bin/kde-shortcuts get kwin "Action Name"`
3. Apply working preset: `bin/apply-shortcuts-preset krohnkite-default`
4. Check System Settings → Shortcuts → Global Shortcuts → KWin

### Configuration Not Applied
1. Ensure files were properly symlinked with stow
2. Restart Plasma: `plasmashell --replace & disown`
3. Reload shortcuts: `bin/kde-shortcuts reload`
4. Log out and back in