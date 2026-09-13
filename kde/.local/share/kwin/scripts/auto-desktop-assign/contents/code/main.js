/*
 * KWin script: Auto-assign windows to virtual desktops by resource class.
 * Plasma 6 (no Qt global in scripts).
 *
 * Position-based (robust to desktop UUID changes):
 *   ghostty (com.mitchellh.ghostty) -> Desktop 1 (index 0)
 *   chromium-lian                   -> Desktop 2 (index 1)
 *   kitty                           -> Desktop 3 (index 2)
 *   alacritty                       -> Desktop 4 (index 3)
 */

var desktopIndexByClass = {
    "com.mitchellh.ghostty": 0, // Desktop 1 - ghostty
    "ghostty":               0, // fallback
    "chromium-lian":         1, // Desktop 2 - lian browser
    "kitty":                 2, // Desktop 3 - kitty
    "alacritty":             3, // Desktop 4 - alacritty
};

function targetDesktopForClass(cls, name) {
    var keys = [cls, name];
    for (var k = 0; k < keys.length; k++) {
        if (!keys[k]) continue;
        var lower = String(keys[k]).toLowerCase();
        if (lower in desktopIndexByClass) {
            var idx = desktopIndexByClass[lower];
            if (idx < workspace.desktops.length) {
                return workspace.desktops[idx];
            }
            return null;
        }
    }
    return null;
}

function assignDesktop(window) {
    // Skip unassignable windows (panels, desktop, dialogs, transients).
    if (window.dock || window.desktopWindow || !window.normalWindow) return;
    if (window.transient) return;

    var target = targetDesktopForClass(window.resourceClass, window.resourceName);
    if (!target) return;

    // Already on the right desktop; don't touch.
    if (window.desktops.length === 1 && window.desktops[0].id === target.id) return;

    window.desktops = [target];
    print("AUTOASSIGN " + window.resourceClass + " -> " + target.name);
}

// Apply to existing windows at script load.
var windows = workspace.windowList();
for (var i = 0; i < windows.length; i++) {
    assignDesktop(windows[i]);
}

// Apply to new windows. resourceClass may not be set yet at windowAdded time,
// so retry on windowClassChanged (no Qt timer needed in Plasma 6).
workspace.windowAdded.connect(function(window) {
    assignDesktop(window);
    window.windowClassChanged.connect(function() {
        assignDesktop(window);
    });
});
