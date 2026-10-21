# AGENTS.md

Agent guide for this dotfiles repo (`arch` branch, Arch Linux, KDE Plasma 6 on Wayland).

## Layout

GNU Stow packages; each top-level dir maps to `$HOME`. Key packages:

| Package | Target | Notes |
|---|---|---|
| `kde` | `~/.config`, `~/.local/share/{kwin,sddm,plasma}` | Plasma, KWin scripts, shortcuts, SDDM/animelock |
| `local-bin` | `~/.local/bin`, `~/.local/share/applications` | helper scripts, Chromium profile launchers |
| `waybar` | `~/.config/waybar`, `~/.config/autostart` | bar config + scripts, autostart entries |
| `alacritty` `kitty` `ghostty` `wezterm` | terminal configs | daily drivers: Ghostty, Kitty, Alacritty |
| `zsh` `bash` `p10k` `tmux` `nvim` `git` `vscode` `rofi` `fcitx5` | shells/editor/tools | nvim is LazyVim (`lazy-lock.json` committed) |
| `bin` | helper scripts | `capture-kde-config`, `sync-kde-config`, `kde-shortcuts`, `apply-shortcuts-preset`, `gen-lockscreen-stills` |

## Setup

```bash
./install.sh   # deps, yay, packages, then stowup — full fresh-Arch bootstrap
./stowup       # stow ALL packages (takes NO package args; fixed list inside)
./stowDown     # unstow all
stow -t ~ <pkg>  # manual single package
```

Live `~/.local` files are real files (not symlinks) — repo holds the tracked copies.
After editing live files, copy them back into the matching package dir before committing.

## Desktop system (must-know)

- **Tiling: Polonium** (`poloniumEnabled=true` in kwinrc). NOT Krohnkite — ignore any
  Krohnkite references in old scripts (`bin/setup-krohnkite` is stale, do not use).
- **10 virtual desktops, always**, named `Desktop 1..10`, top Waybar shows `1..10`:
  - `kde/.local/share/kwin/scripts/keep-10-desktops/` — KWin script, instantly re-inserts
    a deleted desktop into its SAME slot (gap-aware, no renumber shuffle).
  - `local-bin/.local/bin/keep-10-desktops.sh` — daemon backup (2s poll) + autostart
    entry; also owns naming via D-Bus `setDesktopName`.
  - `kde/.local/share/kwin/scripts/auto-desktop-assign/` — pins apps by position:
    Ghostty→1, `chromium-lian`→2, Kitty→3, Alacritty→4 (position-based, UUID-proof).
  - `autonumber-desktops` script CANNOT set names on Plasma 6 — never rely on it.
  - D-Bus API (verified): `qdbus6 org.kde.KWin /VirtualDesktopManager
    org.kde.KWin.VirtualDesktopManager.{count,desktops,createDesktop,removeDesktop,setDesktopName}`
  - Never run `kwin_wayland --replace` / `/KWin replace` — it kills Wayland clients.
    Use `qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure` (safe).
- **Waybar** (`waybar/.config/waybar/`): `custom/current-desktop` renders KWin desktops
  via `scripts/current_desktop.sh`; `custom/updates` uses `checkupdates`, click runs
  `scripts/waybar-update.sh` (`sudo pacman -Syu` in terminal).
- **Chromium profiles**: `chromium-lian` / `chromium-work` wrappers pass
  `--class=chromium-lian|-work` (unique WM class for pinning). `.desktop` files MUST
  use absolute `Exec=/home/sadman/.local/bin/...` — the systemd session PATH lacks
  `~/.local/bin` (see `kde/.config/environment.d/local-bin.conf`, applies at login).
- **pacman `db.lck`**: "unable to lock database" with no pacman running = stale lock
  (e.g. update killed by compositor restart). Fix: `sudo rm /var/lib/pacman/db.lck`.
- **KDE capture workflow**: `./bin/capture-kde-config --force` to snapshot live config.

## Conventions

- Commit style: `<area>: <desc>` (e.g. `kwin: ...`, `waybar: ...`, `autostart: ...`).
- Branch `arch` is this machine; other branches target other machines — keep commits portable.
- Never commit secrets (`.gitignore` covers `.env`, keys, tokens, pycache).
- Symlinks in repo must be RELATIVE (absolute `/home/...` targets break fresh installs).
  System-target links (`/usr/share/applications/*`) are fine.
- Only commit/push when explicitly asked.
