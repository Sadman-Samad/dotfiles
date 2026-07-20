#!/usr/bin/env bash
# hypr-hotedge — bottom-edge hot zone for Hyprland
# When the mouse cursor touches the bottom edge of the screen, opens the
# app launcher (nwg-drawer). Avoids duplicate launches and uses a short
# cooldown so the cursor resting at the edge doesn't spam triggers.
#
# Autostart: exec-once = ~/.config/hypr/scripts/hotedge.sh
# Stop:      pkill -f hotedge.sh

set -u

COMMAND="${1:-nwg-drawer}"
EDGE_PX=2              # how close to the bottom edge counts as "hot"
COOLDOWN_MS=800        # min time between triggers
POLL_MS=200            # cursor poll interval
SCREEN_H=1080          # default; overridden by hyprctl monitors below

# Ensure Wayland env is present so the launched app can reach the compositor.
# When launched from a non-Wayland parent (cron, systemd, etc.) these are missing.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

trigger_zone_y=$((SCREEN_H - EDGE_PX))
last_trigger=0

# Resolve the tallest monitor so the hot zone matches the real bottom.
resolve_geometry() {
    local h
    h=$(hyprctl monitors -j 2>/dev/null \
        | python3 -c "import json,sys; d=json.load(sys.stdin); print(max(m['height']+m['y'] for m in d))" 2>/dev/null)
    [[ -n "${h:-}" ]] && SCREEN_H="$h" && trigger_zone_y=$((SCREEN_H - EDGE_PX))
}

# Check for a live (non-zombie) nwg-drawer instance. We can't use plain
# `pgrep -x` because it matches defunct/zombie processes too, which would
# permanently block the trigger after the first launch.
already_open() {
    [[ -n "$(ps -e -o stat,comm | awk '$1 !~ /^Z/ && $2 == "nwg-drawer"')" ]]
}

resolve_geometry
echo "hotedge: watching cursor, trigger zone y >= $trigger_zone_y (cmd: $COMMAND)"

while true; do
    # Read cursor position: hyprctl returns "x, y"
    pos=$(hyprctl cursorpos 2>/dev/null)
    [[ -z "${pos:-}" ]] && { sleep 0.2; continue; }
    y=${pos#*, }

    now=$(date +%s%3N)
    if (( y >= trigger_zone_y )); then
        if ! already_open && (( now - last_trigger > COOLDOWN_MS )); then
            ($COMMAND >/dev/null 2>&1 & ) &
            last_trigger=$now
        fi
    fi
    sleep 0.2
done
