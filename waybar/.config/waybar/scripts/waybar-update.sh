#!/usr/bin/env bash
# waybar-update.sh — triggered by clicking the updates module in the topbar.
# Opens a terminal, runs a full system upgrade, and waits before closing.
set -euo pipefail

# Pick the first available terminal (matching the user's preferred set).
for term in kitty ghostty alacritty foot; do
    if command -v "$term" >/dev/null 2>&1; then
        TERMINAL="$term"
        break
    fi
done

if [ -z "${TERMINAL:-}" ]; then
    notify-send -u critical "Updates" "No terminal found to run the upgrade."
    exit 1
fi

# Run the upgrade in a fresh shell so the user sees output and can enter their password.
case "$TERMINAL" in
    kitty|foot|alacritty)
        exec "$TERMINAL" -e bash -lc \
            'echo "==> Running system upgrade..."; sudo pacman -Syu; echo; echo "Done. Press Enter to close."; read -r'
        ;;
    ghostty)
        exec "$TERMINAL" -e bash -lc \
            'echo "==> Running system upgrade..."; sudo pacman -Syu; echo; echo "Done. Press Enter to close."; read -r'
        ;;
    *)
        exec "$TERMINAL" -e bash -lc \
            'echo "==> Running system upgrade..."; sudo pacman -Syu; echo; echo "Done. Press Enter to close."; read -r'
        ;;
esac
