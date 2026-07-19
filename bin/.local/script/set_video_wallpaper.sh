#!/usr/bin/env bash
# set_video_wallpaper.sh
# Set a video file as the Plasma 6 desktop wallpaper via PlasmaShell D-Bus.
#
# Usage: set_video_wallpaper.sh <path-to-mp4> [--mute|--unmute] [--loop]
#
# Requires the "Smart Video Wallpaper Reborn" plugin.
# Install it first with: install_video_wallpaper.sh
set -euo pipefail

VIDEO="${1:-}"
MUTE="1"        # 1 = muted (default), 0 = audio on
LOOP="true"

shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --mute)   MUTE="1"; shift ;;
        --unmute) MUTE="0"; shift ;;
        --loop)   LOOP="true"; shift ;;
        --no-loop) LOOP="false"; shift ;;
        *) echo "unknown arg: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$VIDEO" ]; then
    echo "usage: $0 <path-to-mp4> [--mute|--unmute] [--loop|--no-loop]" >&2
    exit 1
fi

VIDEO_ABS=$(readlink -f "$VIDEO")
if [ ! -f "$VIDEO_ABS" ]; then
    echo "file not found: $VIDEO_ABS" >&2
    exit 1
fi

FILE_URI="file://$VIDEO_ABS"
PLUGIN_ID="luisbocanegra.smart.video.wallpaper.reborn"

# Build JSON array matching the plugin's VideoUrls schema:
# {filename, enabled, loop, playbackRate, alternativePlaybackRate, duration, customDuration}
VIDEO_JSON=$(python3 -c "
import json
loop = True if '$LOOP' == 'true' else False
print(json.dumps([{
    'filename': '$FILE_URI',
    'enabled': True,
    'loop': loop,
    'playbackRate': 0,
    'alternativePlaybackRate': 0,
    'duration': 0,
    'customDuration': 0
}]))
")

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var d = desktops()[0];
d.wallpaperPlugin = \"$PLUGIN_ID\";
d.currentConfigGroup = [\"Wallpaper\"];
d.writeConfig(\"VideoBackend\", \"QtMultimedia\");
d.currentConfigGroup = [\"Wallpaper\", \"General\"];
d.writeConfig(\"VideoUrls\", '$VIDEO_JSON');
d.writeConfig(\"MuteMode\", $MUTE);
d.reloadConfig();
" >/dev/null

echo "[set_video_wallpaper] wallpaper set to: $VIDEO_ABS"
echo "[set_video_wallpaper] mute=$MUTE loop=$LOOP"
