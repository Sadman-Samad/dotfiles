/*
 * KWin script: Active Window Title
 *
 * Logs the active window's application class (e.g. "kitty", "chromium") to
 * the journal as "AWT\t<class>" on every focus change. The waybar module
 * resolves the class to a friendly app name via the .desktop file.
 *
 * Plasma 6 KWin scripting API.
 */

var lastCls = "";

function emit(window) {
    var cls = (window && window.resourceClass) ? window.resourceClass : "";
    // On an empty desktop (no active window) keep showing the last app,
    // like macOS.
    if (cls === "" && lastCls !== "") {
        cls = lastCls;
    } else if (cls !== "") {
        lastCls = cls;
    }
    console.log("AWT\t" + cls);
}

// Emit for the window active at load.
emit(workspace.activeWindow);

// Re-emit whenever focus changes.
workspace.windowActivated.connect(function (window) {
    emit(window);
});
