# Ghostty Terminal Configuration

This package contains a Ghostty terminal configuration migrated from the Alacritty setup with the same visual appearance and functionality.

## Features

- **Theme**: Catppuccin Mocha (custom color implementation)
- **Font**: CaskaydiaMono Nerd Font, size 15
- **Window**: 80% opacity, no decorations, 14px padding
- **Shell**: Zsh with login shell
- **Keybindings**: F11 toggles fullscreen

## Installation

```bash
# Install this package
./stowup ghostty

# Or manually
stow -t ~ ghostty
```

## Configuration Structure

```
ghostty/
├── README.md
└── .config/ghostty/
    └── config  # Main Ghostty configuration file
```

## Migration Notes

This configuration was migrated from Alacritty with these key conversions:

- **Format**: Alacritty TOML → Ghostty key=value syntax
- **Colors**: Catppuccin Mocha theme converted to Ghostty color format
- **Window**: Opacity, padding, and decoration settings preserved
- **Font**: Same CaskaydiaMono Nerd Font configuration
- **Keybindings**: F11 fullscreen toggle maintained

## Ghostty-specific Enhancements

- GPU acceleration enabled for better performance
- Improved clipboard handling with paste protection
- Enhanced shell integration features
- Better font rendering with ligature support
- Optimized scrollback buffer management

## Usage

After installation, launch Ghostty from your application menu or terminal:

```bash
ghostty
```

The configuration will be automatically loaded from `~/.config/ghostty/config`.

## Theme Customization

If you prefer to use Ghostty's built-in Catppuccin theme instead of the custom implementation:

1. Edit `~/.config/ghostty/config`
2. Change `theme = catppuccin-mocha` to `theme = Catppuccin Mocha`
3. Remove the custom color definitions

The custom theme is provided for exact color accuracy with the original Alacritty setup.