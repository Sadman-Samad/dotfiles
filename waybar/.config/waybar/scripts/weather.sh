#!/usr/bin/env bash
# Waybar module: weather from wttr.in (auto-detect by IP, no API key).
# Uses wttr.in's JSON endpoint. Cached 15 min to avoid hammering the service.
set -euo pipefail

cache_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-weather"
mkdir -p "$cache_dir"
cache="$cache_dir/latest.json"
ttl=900  # 15 min

# Serve cache if fresh enough.
now=$(date +%s)
mtime=$(date +%s -r "$cache" 2>/dev/null || echo 0)
if [[ -f "$cache" ]] && (( now - mtime < ttl )); then
    : # use cache
elif ! curl -sf --max-time 8 'https://wttr.in/?format=j1' -o "$cache.tmp"; then
    # Network failed: fall back to stale cache if present, else hide module.
    [[ -f "$cache" ]] || { jq -nc '{text:"",tooltip:"Weather unavailable"}'; exit 0; }
else
    mv "$cache.tmp" "$cache"
fi

# Map WMO/worldweatheronline weatherCode → nerd-font icon.
map_icon() {
    case "$1" in
        113) printf '󰖙' ;;   # Clear/Sunny
        116) printf '󰖛' ;;   # Partly cloudy
        119|122) printf '󰖐' ;; # Overcast/Cloudy
        143|248|260) printf '󰖑' ;; # Mist/Fog
        176|263|266|281|284|293|296|299|302|305|308|311|314|317|350|353|356|359|362|365) printf '󰼳' ;; # Rain
        200|386|389) printf '󰙾' ;; # Thunder
        179|182|185|227|230|320|323|326|329|332|335|338|371|374|377|392|395) printf '󰼶' ;; # Snow
        *) printf '󰖐' ;;
    esac
}

code=$(jq -r '.current_condition[0].weatherCode' "$cache")
icon=$(map_icon "$code")

# Build text + rich tooltip. --slurpfile because we use -n (no implicit input).
jq -nc --arg icon "$icon" --slurpfile w "$cache" '
    ($w[0].current_condition[0]) as $c |
    ($w[0].nearest_area[0].areaName[0].value // "Unknown") as $loc |
    {
        text: "\($icon) \($c.temp_C)°C",
        tooltip: "\($loc)\n\($c.weatherDesc[0].value)\nFeels like \($c.FeelsLikeC)°C  •  Humidity \($c.humidity)%\nWind \($c.windspeedKmph) km/h \($c.winddir16Point)"
    }
'
