#!/bin/bash
# Waybar module: Internet latency (ping) to 1.1.1.1 (Cloudflare DNS).
#   - Compact display: RTT in ms, color-coded (green/peach/red).
#   - Hover tooltip: target, sent/recv, jitter note, last checked time.
#
# 1.1.1.1 is chosen because it is highly reliable, anycast, and the de facto
# "is the internet up" target. One packet per interval keeps it cheap.
set -uo pipefail

TARGET="1.1.1.1"

# iputils ping: -c 1 single packet, -W 2 deadline (whole run) in seconds.
raw=$(ping -c 1 -W 2 "$TARGET" 2>&1)

# Extract RTT from a line like: "rtt min/avg/max/mdev = 4.723/4.723/4.723/0.000 ms"
rtt=$(printf '%s\n' "$raw" | grep -oE 'rtt min/avg/max/mdev = [0-9.]+' | grep -oE '[0-9.]+$')

loss=$(printf '%s\n' "$raw" | grep -oE '[0-9]+% packet loss' | grep -oE '^[0-9]+')

now=$(date '+%H:%M:%S')

if [[ -z "$rtt" ]]; then
    # No reply — either 100% loss or an error (host unreachable, no route).
    jq -nc --arg t "$now" \
        '{text:"󰪎  —", tooltip:("Ping failed (no reply from 1.1.1.1)\nChecked: " + $t), class:"down"}'
    exit 0
fi

# Integer compare for color bucketing.
ms_int=${rtt%.*}
if   (( ms_int >= 150 )); then cls="bad"     # red
elif (( ms_int >= 80  )); then cls="warn"    # peach
else                            cls="good"   # green
fi

tip=$(printf 'Target : %s\nLatency: %.1f ms\nLoss  : %s%%\nChecked: %s' \
    "$TARGET" "$rtt" "${loss:-0}" "$now")

jq -nc --arg text "$(printf '󰪎  %.0fms' "$rtt")" \
      --arg tip "$tip" \
      --arg cls "$cls" \
      '{text:$text, tooltip:$tip, class:$cls}'
