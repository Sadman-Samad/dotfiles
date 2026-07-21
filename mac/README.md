# mac2017 branch

Setup for the 2017 Intel Mac (macOS 13 Ventura, i5-7267U).

Other branches (`main`, `arch`, `fedora`) hold Linux setups and are **not** affected by anything here.

## Layout

```
mac/
├── aerospace/aerospace.toml   # AeroSpace tiling WM config
├── brew/Brewfile              # Minimal desktop-app bundle (aerospace, sketchybar, stats, ghostty, kitty, fonts)
├── ghostty/config             # Ghostty terminal config
├── git/gitconfig              # Git config
├── kitty/kitty.conf           # Kitty terminal config
├── p10k/p10k.zsh              # Powerlevel10k prompt
└── zsh/                       # zshrc, zshenv, zprofile
```

## Restore on a fresh macOS

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install desktop apps
brew bundle --file mac/brew/Brewfile

# 3. Symlink configs into $HOME (GNU Stow style)
ln -sf "$PWD/mac/aerospace/aerospace.toml" ~/.aerospace.toml
ln -sf "$PWD/mac/git/gitconfig"            ~/.gitconfig
ln -sf "$PWD/mac/zsh/zshrc"                ~/.zshrc
ln -sf "$PWD/mac/zsh/zshenv"               ~/.zshenv
ln -sf "$PWD/mac/zsh/zprofile"             ~/.zprofile
ln -sf "$PWD/mac/p10k/p10k.zsh"            ~/.p10k.zsh
ln -sf "$PWD/mac/ghostty/config"           "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
ln -sf "$PWD/mac/kitty/kitty.conf"         ~/.config/kitty/kitty.conf

# 4. Enable in macOS
#    - AeroSpace: System Settings → General → Login Items → confirm "Allow in Background"
#      (start-at-login is already true in aerospace.toml)
#    - Stats: open app → Settings → General → Start at login
```

## Workspace layout (AeroSpace)

| Workspace | App    |
|-----------|--------|
| 1         | Ghostty |
| 2         | Lian    |
| 3         | Kitty   |
| 4         | Google Chrome |
