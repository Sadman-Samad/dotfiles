#!/usr/bin/env bash
# Keep 10 virtual desktops on KDE/KWin, named Desktop 1..10.
# Gap-aware: a deleted desktop is re-created in its SAME slot (not appended
# at the end), so the other desktops keep their numbers — no shuffle.
# Polls every 2s (backup for the instant keep-10-desktops KWin script).
set -u
TARGET=10
BUS="org.kde.KWin /VirtualDesktopManager org.kde.KWin.VirtualDesktopManager"

# Print "pos id name" lines for current desktops (name may contain spaces).
list_desktops() {
  # shellcheck disable=SC2086
  qdbus6 --literal $BUS.desktops 2>/dev/null \
    | grep -oE '\(uss\) [0-9]+, "[a-f0-9-]+", "[^"]*"' \
    | sed -E 's/\(uss\) ([0-9]+), "([a-f0-9-]+)", "([^"]*)"/\1 \2 \3/'
}

while true; do
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]] && command -v qdbus6 >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    count=$(qdbus6 $BUS.count 2>/dev/null || echo "$TARGET")
    if [[ "$count" =~ ^[0-9]+$ ]] && (( count < TARGET )); then
      # Fill gaps one at a time, re-reading the list each round: find the
      # first slot whose name mismatches its position and insert there.
      # If all match (deleted the last one), append at the end.
      while (( count < TARGET )); do
        gap=-1
        while read -r pos _did dname; do
          want="Desktop $((pos + 1))"
          if [[ "$dname" != "$want" ]]; then gap=$pos; break; fi
        done < <(list_desktops)
        (( gap == -1 )) && gap=$count
        # shellcheck disable=SC2086
        qdbus6 $BUS.createDesktop "$gap" "Desktop $((gap + 1))" >/dev/null 2>&1
        sleep 0.5
        # shellcheck disable=SC2086
        count=$(qdbus6 $BUS.count 2>/dev/null || echo "$TARGET")
        [[ "$count" =~ ^[0-9]+$ ]] || break
      done
    elif [[ "$count" == "$TARGET" ]]; then
      # Safety net: fix any misnamed desktop (positional naming).
      # `read pos id name` puts the rest of the line into $name.
      while read -r pos did dname; do
        want="Desktop $((pos + 1))"
        if [[ "$dname" != "$want" ]]; then
          # shellcheck disable=SC2086
          qdbus6 $BUS.setDesktopName "$did" "$want" >/dev/null 2>&1
        fi
      done < <(list_desktops)
    fi
    # count > TARGET: leave user's extra desktops alone.
  fi
  sleep 2
done
