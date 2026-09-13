// Keep 10 Desktops — Plasma 6 KWin script.
// Ensures there are always at least 10 virtual desktops (1..10).
// Gap-aware: if one is removed, the replacement is inserted back into the
// SAME slot (not appended at the end), so the other desktops keep their
// numbers and no renaming shuffle happens.
// (Naming fixes for leftover drift are owned by the keep-10-desktops daemon,
// which can call setDesktopName over D-Bus.)

var TARGET_COUNT = 10;

function desktopName(i) {
    return "Desktop " + (i + 1);
}

function ensureTenDesktops() {
    var ds = workspace.desktops;
    if (ds.length >= TARGET_COUNT) {
        return;
    }
    // Find the first slot whose name doesn't match its position —
    // that's where the deleted desktop was (later ones shifted left).
    var gap = -1;
    for (var i = 0; i < ds.length; i++) {
        if (ds[i].name !== desktopName(i)) {
            gap = i;
            break;
        }
    }
    if (gap === -1) {
        gap = ds.length; // deleted the last one (or names clean) -> append
    }
    try {
        // KWin scripting API: createDesktop(position, name) inserts at position.
        workspace.createDesktop(gap, desktopName(gap));
    } catch (e) {
        print("keep-10-desktops error recreating slot " + (gap + 1) + ": " + e);
    }
    // If several are missing, our own creation emits desktopsChanged and this
    // handler runs again for the next gap. Guard above stops us at 10.
}

// Initial pass at script load.
try {
    ensureTenDesktops();
} catch (e) {
    print("keep-10-desktops init error: " + e);
}

// Re-run whenever the desktop set changes (add/remove/reorder).
workspace.desktopsChanged.connect(ensureTenDesktops);
