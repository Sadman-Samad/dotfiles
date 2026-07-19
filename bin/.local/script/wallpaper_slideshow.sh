#!/usr/bin/env bash
# Rotate desktop wallpaper through downloaded anime wallpapers.
# Runs as a daemon; swaps wallpaper every INTERVAL seconds.
# Usage: wallpaper_slideshow.sh [interval_seconds]
#
# Works on:
#   - KDE Plasma 6 (via PlasmaShell D-Bus)
#   - Hyprland (via hyprpaper or swww/awww if available)

set -u
INTERVAL="${1:-1800}"   # default 30 min
DIR="${WALLPAPER_DIR:-$HOME/.local/share/anime-wallpapers}"

# Pick a random wallpaper different from the current one.
pick_next() {
    local current="$1"
    # shellcheck disable=SC2012
    local files
    files=$(ls -1 "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null | grep -v -F "$current" || ls -1 "$DIR"/*.{jpg,jpeg,png,webp} 2>/dev/null)
    [[ -z "$files" ]] && return 1
    printf '%s\n' "$files" | shuf -n 1
}

set_wallpaper_kde() {
    local target="file://$1"
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.setWallpaper \
        "org.kde.image" "{}" 0 2>/dev/null
    # PlasmaShell.setWallpaper signature varies; use script for reliability
    local script
    script=$(printf 'var d = desktops()[0]; d.currentConfigGroup = ["Wallpaper"]; d.writeConfig("Image", "%s"); d.reloadConfig();' "$target")
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script" 2>/dev/null
}

set_wallpaper_hypr() {
    if command -v swww >/dev/null 2>&1; then
        pkill -x swww-daemon 2>/dev/null || true
        swww-daemon &
        sleep 0.5
        swww img "$1" --transition-type grow --transition-duration 1.5
    elif command -v awww >/dev/null 2>&1; then
        pkill -x awww-daemon 2>/dev/null || true
        awww-daemon &
        sleep 0.5
        awww img "$1" --transition-type grow --transition-duration 1.5
    elif command -v hyprpaper >/dev/null 2>&1; then
        # hyprpaper needs IPC; best-effort
        echo "hyprpaper available but no IPC; skipping" >&2
    fi
}

current=""
while true; do
    next=$(pick_next "$current") || { echo "no wallpapers in $DIR" >&2; sleep 60; continue; }
    echo "$(date '+%H:%M:%S') setting: $(basename "$next")"

    if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
        set_wallpaper_kde "$next"
    elif [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        set_wallpaper_hypr "$next"
    else
        echo "unknown session" >&2
    fi

    current="$next"
    sleep "$INTERVAL"
done
