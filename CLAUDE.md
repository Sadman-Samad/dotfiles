# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository using GNU Stow for symlink management. Each top-level directory represents a "package" that maps to corresponding locations in the home directory structure.

## Installation and Management

**Full Installation:**
```bash
./install.sh
```

**Selective Installation:**
```bash
./stowup <package-name>    # Install specific package (e.g., nvim, vscode)
./stowDown <package-name>  # Remove specific package
```

**Manual Stow Commands:**
```bash
stow -t ~ <package-name>   # Create symlinks
stow -D -t ~ <package-name> # Remove symlinks
```

## Architecture and Organization

### Core Philosophy
- Modular package-based organization using GNU Stow
- Vim-centric keybindings across all applications
- Consistent theming (Catppuccin Mocha) and fonts (JetbrainsMono Nerd Font)
- Heavy automation and productivity tooling integration

### Key Packages

**nvim/**: LazyVim-based Neovim configuration
- Uses Lazy.nvim package manager with lazy-lock.json for reproducible builds
- Multi-language support: TypeScript, Go, Dart/Flutter, Python
- GitHub Copilot integration
- Custom plugin configurations in `lua/plugins/`

**vscode/**: VS Code configuration with Vim mode
- Comprehensive Vim keybinding emulation
- Custom transparency and UI settings
- Integrated with system clipboard and terminal

**tmux/**: Terminal multiplexer configuration
- Custom key bindings with prefix `C-a`
- Session management with `tmux-se` script
- Integration with system clipboard

**zsh/**: Shell configuration with Zinit plugin manager
- Powerlevel10k theme configuration
- FZF, Zoxide, and modern CLI tool integrations
- Custom aliases and functions

**hyprland/**: Wayland compositor configuration
- Modular setup: `hyprland.conf` includes `defaults.conf` and `custom.conf`
- Custom keybindings for window management and application launching
- Rofi integration for application launching

**alacritty/**: Terminal emulator configuration
- Catppuccin Mocha theme
- JetbrainsMono Nerd Font
- Optimized for transparency and performance

### Development Workflow Commands

**Tmux Session Management:**
```bash
# Available via bin/tmux-se script
tmux-se <session-name>  # Create or attach to named session
```

**FZF Integration:**
- `Ctrl+R`: Command history search
- `Ctrl+T`: File search
- `Alt+C`: Directory navigation

### Configuration Patterns

**Neovim Plugin Management:**
- Plugins defined in `nvim/.config/nvim/lua/plugins/`
- Lock file at `nvim/.config/nvim/lazy-lock.json`
- Language servers and formatters configured per filetype

**Modular Configuration:**
- Hyprland uses include statements for organization
- Zsh configuration sources multiple files for different concerns
- VS Code settings organized by feature categories

**Cross-Application Integration:**
- Shared clipboard configuration across tmux, nvim, and system
- Consistent keybinding patterns (vim-style navigation)
- Unified theme and font choices

### Development Tools Supported

**Languages:** TypeScript, Go, Dart/Flutter, Python, Lua, Shell
**Tools:** Git, Docker, Node.js, npm/yarn/pnpm, Flutter SDK
**Terminal:** Modern CLI tools (fd, rg, bat, exa, zoxide, fzf)

### File Organization Conventions

- Configuration files follow XDG Base Directory specification
- Binary scripts in `bin/` directory
- Package-specific configurations maintain upstream directory structure
- Lock files and generated content preserved for reproducibility