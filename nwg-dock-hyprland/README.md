# nwg-dock-hyprland

Bottom-edge auto-hiding dock for Hyprland. Native Hyprland support via `hyprctl`
(not the Sway-only `nwg-dock`).

## Why built from source

Fedora repos package only `nwg-dock` (Sway-only — fatals on Hyprland with
`$SWAYSOCK is empty`). `nwg-dock-hyprland` is not packaged for Fedora, so it
must be built from source.

## Build

```bash
# deps (one-time)
sudo dnf install -y gobject-introspection-devel gtk-layer-shell-devel
# gtk-layer-shell pkg-config name is 'gtk-layer-shell-0' (with -0 suffix)

git clone --depth 1 https://github.com/nwg-piotr/nwg-dock-hyprland.git ~/src/nwg-dock-hyprland
cd ~/src/nwg-dock-hyprland
go build -o bin/nwg-dock-hyprland .   # ~14min cold; ~2min with warm GOCACHE
mkdir -p ~/.local/bin ~/.local/share/nwg-dock-hyprland
cp bin/nwg-dock-hyprland ~/.local/bin/
cp config/style.css ~/.local/share/nwg-dock-hyprland/
cp -r images ~/.local/share/nwg-dock-hyprland/
```

## Run

Launched by `hyprland/.config/hypr/autostart.conf`:

```
exec-once = ~/.local/bin/nwg-dock-hyprland -d
```

`-d` = autohiDe: dock stays hidden, appears when the mouse touches the
bottom-center hotspot, hides on click-away or app launch. The dock manages its
own hotspot via the layer shell — no polling loop needed (replaces the old
`hotedge.sh` approach).

## Files

- `.config/nwg-dock-hyprland/style.css` — Catppuccin Mocha theme (matches waybar)
