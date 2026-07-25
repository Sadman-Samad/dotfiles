#!/usr/bin/env bash
# wttr.sh — emit a single waybar line for the custom/weather module.
# Uses wttr.in's IP-based location (auto-detects city). Renders weather
# with a Nerd Font glyph (no emoji font dependency) by mapping wttr's
# text description to an nf-weather-* icon. Caches the result so
# transient network blips don't blank the bar.
#
# Waybar custom-module output: one JSON object per line.
#   {"text": "<visible>", "tooltip": "<on hover>", "class": "..."}
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-wttr"
mkdir -p "$cache_dir"
cache="$cache_dir/last.json"
max_age=540   # 9 min — under the module's 600s interval

# Map wttr.in weather description (%C returns text like "Patchy rain nearby")
# to a Nerd Font nf-weather-* glyph via keyword match. Robust across wttr's
# ~30 phrasings. (All nf-weather-* glyphs verified in JetBrainsMono Nerd Font.)
wttr_to_nf() {
    local d="${1,,}"   # lowercase
    if [[ "$d" == *thunder* || "$d" == *storm* ]]; then printf '\uE305'   # thunderstorm
    elif [[ "$d" == *snow* ]]; then printf '\uE31F'                       # snow
    elif [[ "$d" == *hail* || "$d" == *ice* ]]; then printf '\uE314'      # hail
    elif [[ "$d" == *pouring* || "$d" == *heavy\ rain* || "$d" == *torrential* ]]; then printf '\uE318'  # pouring
    elif [[ "$d" == *rain* || "$d" == *drizzle* || "$d" == *shower* ]]; then printf '\uE319'  # rain
    elif [[ "$d" == *fog* || "$d" == *mist* || "$d" == *haze* ]]; then printf '\uE313'  # fog
    elif [[ "$d" == *wind* || "$d" == *gale* ]]; then printf '\uE31D'     # windy
    elif [[ "$d" == *partly* ]]; then printf '\uE302'                     # partly cloudy
    elif [[ "$d" == *cloud* || "$d" == *overcast* ]]; then printf '\uE32C'  # cloudy
    elif [[ "$d" == *clear* && ( "$d" == *night* || "$d" == *moon* ) ]]; then printf '\uE31E'  # night clear
    elif [[ "$d" == *sunny* || "$d" == *clear* ]]; then printf '\uE30D'   # sunny
    else printf '\uE32C'                                                  # default cloud
    fi
}

fetch() {
    # %l = location(city) | %C = weather description | %t = temperature
    local line
    line="$(curl -fsS --max-time 5 "wttr.in/?format=%l|%C|%t" 2>/dev/null || true)"
    [[ -z "$line" ]] && return 1

    IFS='|' read -r city desc temp <<< "$line"
    [[ -z "$temp" ]] && return 1

    # strip the leading '+' wttr puts on positive temps
    temp="${temp#+}"

    local icon
    icon="$(wttr_to_nf "$desc")"

    local text tooltip
    text="${icon} ${temp}"
    tooltip="${city} — ${desc:-weather} ${temp}"

    printf '{"text":"%s","tooltip":"%s","class":"weather"}\n' \
        "$text" "$tooltip" > "$cache"
}

# Refresh if cache missing or stale; always fall back to last good cache.
if [[ ! -f "$cache" ]] || \
   [[ $(( $(date +%s) - $(stat -c %Y "$cache") )) -gt $max_age ]]; then
    fetch || true
fi

if [[ -f "$cache" ]]; then
    cat "$cache"
else
    printf '{"text":"  --","tooltip":"weather unavailable","class":"weather"}\n'
fi
