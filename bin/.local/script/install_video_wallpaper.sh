#!/usr/bin/env bash
# install_video_wallpaper.sh
# Installs the "Smart Video Wallpaper Reborn" Plasma 6 plugin to the user's
# local directory (no sudo required) and prepares the live-wallpaper folder.
# Repo: https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn
set -euo pipefail

PLUGIN_ID="luisbocanegra.smart.video.wallpaper.reborn"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/$PLUGIN_ID"
WALLPAPER_DIR="$HOME/.local/share/live-wallpapers"
REPO_API="https://api.github.com/repos/luisbocanegra/plasma-smart-video-wallpaper-reborn/releases/latest"

# 1. Prepare live-wallpaper directory
mkdir -p "$WALLPAPER_DIR"

# 2. Skip if already installed
if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/metadata.json" ]; then
    echo "[install_video_wallpaper] already installed at $PLUGIN_DIR"
    exit 0
fi

# 3. Fetch latest release tarball URL
echo "[install_video_wallpaper] fetching latest release..."
TARBALL_URL=$(curl -fsSL "$REPO_API" \
    | grep -oE 'browser_download_url": "[^"]+\.tar\.gz"' \
    | head -1 \
    | sed -E 's/browser_download_url": "//; s/"$//')

if [ -z "$TARBALL_URL" ]; then
    echo "[install_video_wallpaper] ERROR: could not find release tarball" >&2
    exit 1
fi

# 4. Download and extract
TMP=$(mktemp -d)
echo "[install_video_wallpaper] downloading $TARBALL_URL"
curl -fsSL -o "$TMP/plugin.tar.gz" "$TARBALL_URL"

mkdir -p "$PLUGIN_DIR"
tar xzf "$TMP/plugin.tar.gz" -C "$PLUGIN_DIR"
rm -rf "$TMP"

# 5. Verify
if [ -f "$PLUGIN_DIR/metadata.json" ]; then
    echo "[install_video_wallpaper] installed $PLUGIN_ID -> $PLUGIN_DIR"
    echo "[install_video_wallpaper] restart plasmashell to activate:"
    echo "    systemctl --user restart plasma-plasmashell"
else
    echo "[install_video_wallpaper] ERROR: install failed" >&2
    exit 1
fi
