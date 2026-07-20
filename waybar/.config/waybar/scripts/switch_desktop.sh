#!/usr/bin/env bash
# Switch the active virtual desktop / workspace.
# Usage:
#   switch_desktop.sh next     # go right
#   switch_desktop.sh prev     # go left
#   switch_desktop.sh 3        # go to workspace/desktop N (1-indexed)
#
# Works on both Hyprland and KDE Plasma (KWin).

set -u
target="${1:-next}"

# --- Hyprland -------------------------------------------------------------
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  case "$target" in
    next) hyprctl dispatch workspace +1 ;;
    prev) hyprctl dispatch workspace -1 ;;
    *)    hyprctl dispatch workspace "$target" ;;
  esac
  exit 0
fi

# --- KDE Plasma (KWin via D-Bus) -----------------------------------------
if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && command -v qdbus6 >/dev/null 2>&1; then
  case "$target" in
    next) qdbus6 org.kde.KWin /KWin org.kde.KWin.nextDesktop ;;
    prev) qdbus6 org.kde.KWin /KWin org.kde.KWin.previousDesktop ;;
    *)
      if [[ "$target" =~ ^[0-9]+$ ]]; then
        qdbus6 org.kde.KWin /KWin org.kde.KWin.setCurrentDesktop "$target"
      else
        echo "invalid target: $target" >&2
        exit 1
      fi
      ;;
  esac
  exit 0
fi

echo "no supported session" >&2
exit 1
