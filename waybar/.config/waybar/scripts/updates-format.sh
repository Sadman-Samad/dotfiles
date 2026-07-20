#!/usr/bin/env bash
# Waybar module: pending Arch package updates.
# Uses checkupdates (pacman-contrib): temp sync DB, no root.
# Emits empty text when no updates → waybar hides the module.
set -euo pipefail

# checkupdates prints `<name> <oldver> -> <newver>` per pending upgrade.
# Exit code is unreliable across versions (0/1/2); rely on stdout only.
updates=$(checkupdates 2>/dev/null || true)
count=$(printf '%s\n' "$updates" | grep -c . || true)

if (( count == 0 )); then
    # Empty text → waybar hides the module entirely.
    jq -nc '{text: "", class: "updated", tooltip: "System is up to date"}'
else
    text="󰚰  ${count} update"
    (( count > 1 )) && text+="s"
    tooltip="<b>${count} pending update(s):</b>\n${updates}"
    jq -nc --arg t "$text" --arg tip "$tooltip" \
        '{text: $t, class: "pending", tooltip: $tip, percentage: 0}'
fi
