#!/bin/bash
# SwiftBar weather plugin — pulls from wttr.in (no API key needed)
# Refresh: every 1 hour (filename suffix .1h.sh)
# Customize city below or set WTTR_LOCATION env var

LOCATION="${WTTR_LOCATION:-Dhaka}"
# Use a fixed timezone string so the script works regardless of where it runs
WTTR_URL="https://wttr.in/${LOCATION// /+}?format=j1"

# Fetch weather JSON
JSON=$(curl -sf --max-time 8 "$WTTR_URL")

if [ -z "$JSON" ]; then
    echo "⛅️ --"
    echo "---"
    echo "weather unavailable"
    exit 0
fi

# Current condition
CURR_DESC=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['weatherDesc'][0]['value'])" 2>/dev/null)
CURR_TEMP=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['temp_C'])" 2>/dev/null)
CURR_FEELS=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['FeelsLikeC'])" 2>/dev/null)
HUMIDITY=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['humidity'])" 2>/dev/null)
WIND=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['windspeedKmph'])" 2>/dev/null)

# Pick emoji based on weatherCode
WEATHER_CODE=$(echo "$JSON" | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['weatherCode'])" 2>/dev/null)
case "$WEATHER_CODE" in
    113) EMOJI="☀️" ;;
    116) EMOJI="⛅️" ;;
    119|122) EMOJI="☁️" ;;
    143|248|260) EMOJI="🌫️" ;;
    176|263|266|281|284|293|296|299|302|305|308|311) EMOJI="🌧️" ;;
    200) EMOJI="⛈️" ;;
    179|182|185|227|230|311|314|317|320|323|326|329|332|335|338|350|353|356|359|362|365) EMOJI="🌨️" ;;
    377|374|371|368|365|338) EMOJI="❄️" ;;
    *) EMOJI="🌡️" ;;
esac

# Menu bar: emoji + temp
echo "${EMOJI} ${CURR_TEMP}°C"
echo "---"

# Dropdown: details
echo "Feels like: ${CURR_FEELS}°C"
echo "Condition: ${CURR_DESC}"
echo "Humidity: ${HUMIDITY}%"
echo "Wind: ${WIND} km/h"
echo "Location: ${LOCATION}"
echo "---"

# 3-day forecast (wttr.in weather field)
echo "$JSON" | /usr/bin/python3 -c "
import sys, json
d = json.load(sys.stdin)
for day in d.get('weather', []):
    date = day['date']
    max_t = day['maxtempC']
    min_t = day['mintempC']
    desc = day['hourly'][4]['weatherDesc'][0]['value']
    print(f'{date}: {desc}, {min_t}–{max_t}°C')
" 2>/dev/null
