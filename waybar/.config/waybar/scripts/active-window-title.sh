#!/bin/bash
# active-window-title.sh — waybar custom module
#
# Shows the name of the currently-focused application (macOS-style) in the
# topbar.
#
# Source: the KWin script "active-window-title" logs the active window's
# resourceClass (e.g. "kitty", "chromium") as "AWT\t<class>". We resolve that
# to a friendly name from the app's .desktop file (Name=), capitalizing as a
# fallback. Updates instantly via journal follow (-f).

set -euo pipefail

declare -A CACHE

resolve_name() {
    local cls="$1"
    [ -z "$cls" ] && { echo "Desktop"; return; }
    # Cached?
    [ -n "${CACHE[$cls]:-}" ] && { echo "${CACHE[$cls]}"; return; }

    local name=""
    # Search common application dirs for a matching .desktop file.
    local f
    for f in \
        "/usr/share/applications/${cls}.desktop" \
        "/usr/share/applications/org.${cls}.desktop" \
        "/home/${USER:-sadman}/.local/share/applications/${cls}.desktop"; do
        if [ -f "$f" ]; then
            # First unlocalised Name= line.
            name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
            break
        fi
    done

    # Fallback: capitalise the class ("chromium" -> "Chromium"; strip a
    # "org." or reverse-domain prefix if present).
    if [ -z "$name" ]; then
        local bare="${cls##*.}"   # com.mitchellh.ghostty -> ghostty
        name="$(printf '%s' "${bare:0:1}" | tr '[:lower:]' '[:upper:]')${bare:1}"
    fi

    CACHE[$cls]="$name"
    echo "$name"
}

emit() {
    printf '{"text":"%s","tooltip":"%s","class":"active-window"}\n' "$1" "$1"
}

# Prime with the most recent value before following.
LAST=$(journalctl --user -t kwin_wayland -o cat --no-pager 2>/dev/null \
       | grep -F 'AWT' | tail -n1 || true)
LAST="${LAST#AWT	}"
[ -n "$LAST" ] && emit "$(resolve_name "$LAST")"

# Follow the journal: push only NEW entries, skip empty classes.
journalctl --user -t kwin_wayland -o cat --no-pager -n 0 -f 2>/dev/null \
    | grep --line-buffered -F 'AWT' \
    | while IFS= read -r line; do
        v="${line#AWT	}"
        [ -n "$v" ] && emit "$(resolve_name "$v")"
    done
