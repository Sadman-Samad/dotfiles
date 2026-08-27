#!/bin/bash
# Waybar module: compact network throughput (replaces the built-in network module
# for speed display; keeps the module for interface/IP info in format-alt).
#   - Bar: 󰛳 3.2M↓ 256K↑  (IEC units, no "/s", no spaces inside a reading)
#   - Hover: totals since boot + current rates.
#
# Reading kernel counters directly is cheaper than spawning vnstat and works
# even when the network module's IPC isn't reachable.
set -uo pipefail

IFACE="${IFACE:-enp34s0}"
RXF="/sys/class/net/$IFACE/statistics/rx_bytes"
TXF="/sys/class/net/$IFACE/statistics/tx_bytes"

# $1 = bytes, $2 = decimals. IEC sizes: 1024-based, one-letter unit.
fmt() {
    awk -v b="$1" -v d="$2" 'BEGIN {
        split("B K M G T", u, " ");
        i = 1;
        while (b >= 1024 && i < 5) { b /= 1024; i++ }
        printf "%." d "f%s", b, u[i]
    }'
}

rx1=$(cat "$RXF" 2>/dev/null) || { jq -nc '{text:"󰛳  —"}'; exit 0; }
tx1=$(cat "$TXF" 2>/dev/null) || { jq -nc '{text:"󰛳  —"}'; exit 0; }
sleep 1
rx2=$(cat "$RXF" 2>/dev/null)
tx2=$(cat "$TXF" 2>/dev/null)

down=$((rx2 - rx1)); up=$((tx2 - tx1))
(( down < 0 )) && down=0
(( up < 0 )) && up=0

tip=$(printf 'Interface : %s\nDown now  : %s/s\nUp now    : %s/s\nTotal rx  : %s\nTotal tx  : %s' \
    "$IFACE" "$(fmt "$down" 1)" "$(fmt "$up" 1)" "$(fmt "$rx2" 1)" "$(fmt "$tx2" 1)")

jq -nc --arg text "󰛳 $(fmt "$down" 0)↓ $(fmt "$up" 0)↑" \
      --arg tooltip "$tip" \
      '{text:$text, tooltip:$tooltip}'
