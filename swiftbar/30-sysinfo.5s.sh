#!/bin/bash
# SwiftBar sysinfo plugin — CPU temp + fan speed
# Refresh: every 5 seconds (filename suffix .5s.sh)
# Requires: istats (gem install iStats)

# --- CPU temp ---
CPU_TEMP=$(istats cpu temp --value-only 2>/dev/null | awk '{printf "%.0f", $1}')

# --- Fans ---
FANS=$(istats fan speed --value-only 2>/dev/null)
FAN0=$(echo "$FANS" | sed -n '1p' | awk '{print $1}')
FAN1=$(echo "$FANS" | sed -n '2p' | awk '{print $1}')

# --- Menu bar ---
echo "🌡️ ${CPU_TEMP}°C 🌀${FAN0}"
echo "---"
echo "CPU temp: ${CPU_TEMP}°C"
echo "Fan 0: ${FAN0} RPM"
echo "Fan 1: ${FAN1} RPM"
