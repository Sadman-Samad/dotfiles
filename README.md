# Dotfiles

Personal development environment for **Arch Linux** (this is the `arch` branch).
Other branches (`main`, `mac`, `m1`, `m2`, `server`, etc.) hold setups for other machines.

## Setup on a fresh Arch install

```bash
# 1. Clone to home directory
git clone -b arch git@github.com:Sadman-Samad/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Install packages + apply configs (stow)
./install.sh
```

Or apply individual packages with [GNU Stow](https://www.gnu.org/software/stow/):

```bash
./stowup      # stow all packages (symlinks configs into ~)
./stowDown    # unstow all packages
```

## Packages

| Package | What it configures |
|---|---|
| `alacritty` `kitty` `wezterm` `ghostty` | terminals |
| `zsh` `bash` `p10k` | shells + prompt |
| `tmux` `nvim` | editor/multiplexer |
| `waybar` | status bar (12h clock, weather, pacman-updates modules) |
| `hyprland` | Hyprland compositor + hypridle |
| `rofi` `fcitx5` | launcher + input method |
| `kde` | KDE Plasma configs (shortcuts, kwin, window rules, panel) |
| `git` | git identity |
| `bin` | helper scripts (~/.local/script, ~/bin) |
| `vscode` | VSCode keybindings/settings |

## Capturing live KDE config after changes

```bash
./bin/capture-kde-config --force
```
