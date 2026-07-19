# dotfiles

My personal Arch Linux rice — zsh + Powerlevel10k, tmux, LazyVim, Hyprland,
ghostty/alacritty, rofi. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a stow package that mirrors paths from `$HOME`:

| Package     | What it installs                                         |
| ----------- | -------------------------------------------------------- |
| `zsh`       | `.zshrc` (zinit + p10k + fzf/zoxide/eza integrations)    |
| `p10k`      | `.p10k.zsh` prompt config                                |
| `bash`      | `.bashrc`                                                |
| `git`       | `.gitconfig`                                             |
| `tmux`      | `.tmux.conf` (tpm, catppuccin, vim-tmux-navigator)       |
| `nvim`      | `~/.config/nvim` — LazyVim distribution + plugins        |
| `alacritty` | `~/.config/alacritty` (Catppuccin Mocha)                 |
| `ghostty`   | `~/.config/ghostty/config`                               |
| `hyprland`  | `~/.config/hypr` — full rice (hyprland/hypridle/hyprlock)|
| `rofi`      | `~/.config/rofi` (Catppuccin Mocha)                      |
| `vscodium`  | VScodium `User/` settings + keybindings                  |
| `bin`       | `~/.local/script` helpers (`tmux-se`)                    |

## Install

```sh
git clone git@github.com:Sadman-Samad/dotfiles.git ~/dotfiles
cd ~/dotfiles
./stowup          # stow all packages, or: stow zsh tmux nvim ...
```

`stowDown` removes every package's symlinks.

## Prerequisites (Arch)

```sh
sudo pacman -S stow zsh tmux neovim git fzf fd ripgrep zoxide eza bat \
               ghc hyprland rofi alacritty ghostty
chsh -s /usr/bin/zsh
# tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# then inside tmux: prefix + I
```

Fonts: `ttf-jetbrains-mono-nerd`. Theme: Catppuccin Mocha (baked into the
terminal configs).

## Notes

- `~/.zshrc` expects this repo at `~/dotfiles` (it adds `$HOME/dotfiles` and
  `$HOME/.local/script` to `PATH`) and aliases `t`/`fp` to `tmux-se`.
- After stowing `nvim`, plugins install automatically on first launch via
  lazy.nvim; `lazy-lock.json` pins versions.
- Hyprland config is split under `~/.config/hypr/{hyprland,hyprlock,custom}/`.
