#!/bin/bash
# active-window-title.sh — waybar custom module for Hyprland
#
# Shows the focused app's icon + name in the topbar.
# Event-driven via hyprland IPC socket2.

set -uo pipefail

resolve_desktop_file() {
    local cls="$1"
    # Direct match
    for f in \
        "/usr/share/applications/${cls}.desktop" \
        "/usr/share/applications/org.${cls}.desktop" \
        "/usr/share/applications/com.${cls}.desktop" \
        "$HOME/.local/share/applications/${cls}.desktop"; do
        [ -f "$f" ] && { echo "$f"; return; }
    done
    # Reverse-domain full match (e.g. com.mitchellh.ghostty)
    if [[ "$cls" == *.* ]]; then
        for f in "/usr/share/applications/${cls}.desktop" \
                 "$HOME/.local/share/applications/${cls}.desktop"; do
            [ -f "$f" ] && { echo "$f"; return; }
        done
    fi
    echo ""
}

resolve_name() {
    local cls="$1"
    [ -z "$cls" ] && { echo ""; return; }

    local desktop_file
    desktop_file=$(resolve_desktop_file "$cls")

    if [ -n "$desktop_file" ]; then
        grep -m1 '^Name=' "$desktop_file" | cut -d= -f2-
        return
    fi

    # Fallback: capitalise the bare class name
    local bare="${cls##*.}"
    echo -n "${bare:0:1}" | tr '[:lower:]' '[:upper:]'
    echo "${bare:1}"
}

resolve_icon_name() {
    local cls="$1"
    [ -z "$cls" ] && { echo ""; return; }

    local desktop_file
    desktop_file=$(resolve_desktop_file "$cls")

    if [ -n "$desktop_file" ]; then
        grep -m1 '^Icon=' "$desktop_file" | cut -d= -f2-
        return
    fi
    echo ""
}

emit() {
    local cls="$1"
    local css_class="active-window"

    if [ -z "$cls" ]; then
        printf '{"text":"","class":"%s empty"}\n' "$css_class"
        return
    fi

    local name icon
    name=$(resolve_name "$cls")
    icon=$(resolve_icon_name "$cls")

    [ -z "$name" ] && { printf '{"text":"","class":"%s empty"}\n' "$css_class"; return; }

    # Nerd Font icon per app class. Falls back to a generic window icon.
    declare -A ICONS=(
        [kitty]=󰄛 [Kitty]=󰄛
        [ghostty]=󰄛 [com.mitchellh.ghostty]=󰄛
        [Alacritty]=󰄛 [alacritty]=󰄛
        [foot]=󰆍 [footclient]=󰆍
        [chromium]=󰊯 [Chromium]=󰊯 [google-chrome]=󰊯
        [firefox]=󰈹 [firefoxdeveloperedition]=󰈹
        [Code]=󰨞 [code-oss]=󰨞 [VSCodium]=󰨞
        [Spotify]=󰓇 [spotify]=󰓇
        [Discord]=󰙯 [discord]=󰙯
        [Steam]=󰓓 [steam]=󰓓
        [dolphin]=󰉋 [org.kde.dolphin]=󰉋 [nautilus]=󰉋 [Thunar]=󰉋
        [Gimp]=󰋩 [gimp]=󰋩
        [inkscape]=󰋩 [Inkscape]=󰋩
        [obs]=󰄜 [com.obsproject.Studio]=󰄜
        [telegram-desktop]=󰭂 [org.telegram.desktop]=󰭂
        [pwvucontrol]=󰕟 [pavucontrol]=󰕟
        [easyeffects]=󰕟
        [imv]=󰋩 [feh]=󰋩 [nomacs]=󰋩
        [mpv]=󰝚 [vlc]=󰝚
        [Thunderbird]=󰇮 [thunderbird]=󰇮
        [Obsidian]=󰠮 [obsidian]=󰠮
        [wlogout]=󰐥
    )
    local icon="${ICONS[$cls]:-󰋒}"

    local text="${icon}  ${name}"

    # jq handles all escaping safely.
    jq -nc --arg text "$text" --arg tip "$name" --arg cls "$css_class" \
        '{text: $text, tooltip: $tip, class: $cls}'
}

get_active_class() {
    hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty'
}

# Find the socket2 path
SOCK2="${XDG_RUNTIME_DIR:-/run/user/1000}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

# Emit current window immediately
emit "$(get_active_class)"

# Follow events
if [ -S "$SOCK2" ]; then
    exec socat -U - "UNIX-CONNECT:${SOCK2}" 2>/dev/null | \
        while IFS= read -r _; do
            emit "$(get_active_class)"
        done
else
    # Fallback: poll every 1s if socket not found
    while true; do
        emit "$(get_active_class)"
        sleep 1
    done
fi
