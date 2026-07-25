#!/usr/bin/env bash
# close-floating.sh — close the active overlay or floating window.
# Bound to bare Escape. Tries layer-shell overlays first (wofi etc.),
# then falls back to closing a floating Hyprland window if one is focused.
set -euo pipefail

# 1. Layer-shell / standalone overlay apps that Hyprland doesn't manage as windows.
#    (activewindow/clients can't see them, so we kill by name.)
overlays=(wofi wlogout fuzzel rofi tofi bemenu dmenu walker pavucontrol)
for app in "${overlays[@]}"; do
    if pgrep -x "$app" >/dev/null 2>&1; then
        pkill -x "$app" 2>/dev/null || true
        exit 0
    fi
done

# 2. Floating Hyprland window (pavucontrol when not in overlay list, dialogs, etc.)
active="$(hyprctl -j activewindow 2>/dev/null || echo '{}')"
floating="$(printf '%s' "$active" | jq -r '.floating // false')"
class="$(printf '%s' "$active" | jq -r '.class // empty')"

if [[ "$floating" == "true" && -n "$class" ]]; then
    hyprctl dispatch closewindow "class:^${class}\$" >/dev/null
fi
