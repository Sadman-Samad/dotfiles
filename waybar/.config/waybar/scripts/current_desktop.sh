#!/usr/bin/env bash
# Reports current virtual desktop / workspace for waybar.
# Works on both Hyprland and KDE Plasma (KWin).
#
# Output (two lines):
#   line 1: bar text, e.g. "1 [2] 3 4"  (all desktops, current bracketed)
#   line 2: tooltip text
#
# Exit 0 with empty output if no supported session is detected; waybar
# will then hide the custom module via its empty "format".

set -u

# --- Hyprland -------------------------------------------------------------
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
  active=$(hyprctl activeworkspace -j | jq -r '.id // empty' 2>/dev/null)
  if [[ -n "$active" ]]; then
    # Render workspaces 1..10; mark the active one with brackets.
    out=""
    for i in 1 2 3 4 5 6 7 8 9 10; do
      if (( i == active )); then out+="[$i] "; else out+="$i "; fi
    done
    printf '󰹯  %s\n' "${out% }"
    name=$(hyprctl workspaces -j | jq -r --argjson id "$active" \
           '.[] | select(.id == $id) | .name // empty' 2>/dev/null)
    printf 'Workspace %s%s' "$active" "${name:+ ($name)}"
    exit 0
  fi
fi

# --- KDE Plasma (KWin via D-Bus) -----------------------------------------
if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && command -v qdbus6 >/dev/null 2>&1; then
  current_id=$(qdbus6 org.kde.KWin /VirtualDesktopManager \
               org.kde.KWin.VirtualDesktopManager.current 2>/dev/null)
  if [[ -n "$current_id" ]]; then
    # desktops is a(uss): array of (uint position, str id, str name).
    # Parse with grep+awk into "position:id:name" lines.
    mapfile -t rows < <(qdbus6 --literal org.kde.KWin /VirtualDesktopManager \
                        org.kde.KWin.VirtualDesktopManager.desktops 2>/dev/null \
                        | grep -oE '\(uss\) [0-9]+, "[a-f0-9-]+", "[^"]*"' \
                        | sed -E 's/\(uss\) ([0-9]+), "([a-f0-9-]+)", "([^"]*)"/\1:\2:\3/')
    out=""
    current_name=""
    current_pos=0
    total=0
    for row in "${rows[@]}"; do
      IFS=':' read -r pos id name <<< "$row"
      pos1=$(( pos + 1 ))
      total=$(( total + 1 ))
      if [[ "$id" == "$current_id" ]]; then
        out+="[$pos1] "
        current_name="$name"
        current_pos="$pos1"
      else
        out+="$pos1 "
      fi
    done
    printf '󰹯  %s\n' "${out% }"
    printf 'Desktop %d of %d (%s)' "$current_pos" "$total" "$current_name"
    exit 0
  fi
fi

# --- No supported session -------------------------------------------------
exit 0
