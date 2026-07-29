/*
 * KWin script: Active Window Title
 *
 * Logs the active window's application class (e.g. "kitty", "chromium") to
 * the journal as "AWT\t<class>" on every focus change. The waybar module
 * resolves the class to a friendly app name via the .desktop file.
 *
 * Plasma 6 KWin scripting API.
 */

function emit(window) {
    var cls = (window && window.resourceClass) ? window.resourceClass : "";
    console.log("AWT\t" + cls);
}

// Emit for the window active at load.
emit(workspace.activeWindow);

// Re-emit whenever focus changes.
workspace.windowActivated.connect(function (window) {
    emit(window);
});
