#!/usr/bin/env bash
# Download trending SFW anime wallpapers from wallhaven.cc
# Usage: fetch_wallpapers.sh [count]
set -u

DIR="${WALLPAPER_DIR:-$HOME/.local/share/anime-wallpapers}"
mkdir -p "$DIR"
COUNT="${1:-20}"

# wallhaven API v1:
#   categories=010   = anime only (general/people/sketch = 0, anime = 1)
#   purity=100       = SFW only (sfw/sketchy/nsfw = 1/0/0)
#   atleast=1920x1080
#   sorting=toplist topRange=1M  = top-favorited this month ("trending")
#   q=anime
API="https://wallhaven.cc/api/v1/search?categories=010&purity=100&atleast=1920x1080&sorting=toplist&topRange=1M&q=anime&ppi=100"

resp=$(curl -fsS "$API" ) || { echo "wallhaven API failed" >&2; exit 1; }

# Extract image URLs (the full-resolution path field)
urls=$(printf '%s\n' "$resp" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for item in data.get('data', []):
    print(item.get('path', ''))
")

n=0
while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    fname=$(basename "$url")
    if [[ -f "$DIR/$fname" ]]; then
        echo "skip (have): $fname"
    else
        echo "fetch: $fname"
        curl -fsS -o "$DIR/$fname" "$url" || { echo "  failed: $url" >&2; continue; }
    fi
    n=$((n+1))
    (( n >= COUNT )) && break
done <<< "$urls"

echo "done: $n wallpapers in $DIR"
ls -1 "$DIR" | wc -l | xargs -I{} echo "total: {} files"
