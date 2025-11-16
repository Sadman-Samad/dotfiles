# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    # Check if we're in live environment
    if grep -q "archisolabel" /proc/cmdline 2>/dev/null; then
        # Run welcome script which starts Hyprland
        exec /root/welcome.sh
    fi
fi