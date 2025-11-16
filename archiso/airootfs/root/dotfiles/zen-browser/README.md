# Zen Browser Configuration

This package contains configuration for [Zen Browser](https://zen-browser.app/), a Firefox-based browser focused on privacy and customization.

## What's Included

- **profiles.ini**: Profile configuration
- **profile-template/**: Template directory with customizable settings
  - `zen-keyboard-shortcuts.json`: Custom keyboard shortcuts
  - `zen-themes.json`: Theme configuration (currently using "Transparent Zen" theme)
  - `chrome/zen-themes.css`: Custom CSS for theme styling
  - `chrome/zen-themes/`: Theme files and assets

## Installation

### First Time Setup

1. **Install Zen Browser** if you haven't already:
   ```bash
   yay -S zen-browser-bin
   # or
   flatpak install flathub io.github.zen_browser.zen
   ```

2. **Launch Zen Browser** once to create the initial profile structure:
   ```bash
   zen-browser
   ```

3. **Find your profile directory**:
   ```bash
   ls ~/.zen/
   ```
   Look for a directory like `xxxxxxxx.Default (release)` - this is your active profile.

4. **Copy the template configuration to your profile**:
   ```bash
   PROFILE_DIR=$(ls -d ~/.zen/*.Default\ \(release\) | head -n1)
   cp -r ~/dotfiles/zen-browser/.zen/profile-template/* "$PROFILE_DIR/"
   ```

5. **Restart Zen Browser** to apply the settings.

### Syncing with Stow

To link the profiles.ini (which tracks which profile is active):

```bash
cd ~/dotfiles
stow zen-browser
```

Or use the helper script:
```bash
./stowup zen-browser
```

## Configuration Files Explained

### zen-keyboard-shortcuts.json

Contains custom keyboard shortcuts for:
- **Window & Tab Management**: Alt+1-9 for tab switching, Ctrl+W to close tabs
- **Compact Mode**: Ctrl+S to toggle, Alt+Ctrl+S to show sidebar, Alt+Ctrl+T to show toolbar
- **Workspace Management**: Alt+Ctrl+← and Alt+Ctrl+→ to navigate workspaces
- **Split View**: Alt+Ctrl+H (horizontal), Alt+Ctrl+V (vertical), Alt+Ctrl+G (grid), Alt+Ctrl+U (unsplit)
- **Zen-specific**: Ctrl+O for Glance expand, Shift+Ctrl+C to copy URL, Alt+Shift+Ctrl+C to copy as markdown

### zen-themes.json

Defines the active theme configuration. Currently configured with:
- **Transparent Zen theme**: Provides transparency, smooth animations, and modern styling
- Features include:
  - Transparent background and sidebar
  - Smooth tab switching animations
  - URL bar zoom animation
  - Trackpad gesture animations
  - Custom no-tab image (Zen logo)

### chrome/zen-themes.css

Custom CSS that implements the theme's visual styling using:
- CSS variables for colors and transparency
- Animation transitions with cubic-bezier easing
- Responsive layouts for compact mode
- Mask and push effects for the sidebar

## Customization

### Adding Custom CSS

Create or edit `userChrome.css` in your profile's chrome directory:

```bash
PROFILE_DIR=$(ls -d ~/.zen/*.Default\ \(release\) | head -n1)
nano "$PROFILE_DIR/chrome/userChrome.css"
```

### Adding Custom Preferences

Create a `user.js` file in your profile directory:

```bash
PROFILE_DIR=$(ls -d ~/.zen/*.Default\ \(release\) | head -n1)
nano "$PROFILE_DIR/user.js"
```

Example preferences:
```javascript
// Enable userChrome.css support
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Hardware acceleration
user_pref("gfx.webrender.all", true);
user_pref("layers.acceleration.force-enabled", true);

// Privacy settings
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
```

## Theme Features

The **Transparent Zen** theme provides:

1. **Transparency Effects**
   - Transparent main browser background
   - Transparent sidebar option
   - Transparent glance view

2. **Smooth Animations**
   - Tab switching with scale and opacity transitions
   - URL bar zoom effect when focused
   - Trackpad gesture animations
   - Configurable animation speeds (0-3 levels)

3. **Compact Mode Options**
   - **Mask type**: Content masked behind sidebar
   - **Push type**: Content pushed when sidebar appears
   - Customizable sidebar width

4. **Visual Enhancements**
   - No-shadow option for cleaner look
   - Tab tint options (light/transparent)
   - Custom background image when no tab is open

## Updating Configuration

To update the dotfiles with your current Zen Browser configuration:

```bash
# Update keyboard shortcuts
PROFILE_DIR=$(ls -d ~/.zen/*.Default\ \(release\) | head -n1)
cp "$PROFILE_DIR/zen-keyboard-shortcuts.json" ~/dotfiles/zen-browser/.zen/profile-template/

# Update themes
cp "$PROFILE_DIR/zen-themes.json" ~/dotfiles/zen-browser/.zen/profile-template/
cp "$PROFILE_DIR/chrome/zen-themes.css" ~/dotfiles/zen-browser/.zen/profile-template/chrome/

# Update theme assets
cp -r "$PROFILE_DIR/chrome/zen-themes/"* ~/dotfiles/zen-browser/.zen/profile-template/chrome/zen-themes/
```

## Troubleshooting

### Configuration Not Applied

1. Ensure you copied files to the correct profile directory
2. Restart Zen Browser completely (not just close the window)
3. Check that the profile directory name in `~/.zen/` matches your active profile

### Theme Not Working

1. Verify theme files are in the chrome directory
2. Check that `zen-themes.json` references the correct theme ID
3. Try disabling and re-enabling the theme in Zen Browser settings

### Keyboard Shortcuts Not Working

1. Check for conflicts with system shortcuts
2. Verify the shortcuts file is in the profile root (not in chrome/)
3. Restart Zen Browser after making changes

## Architecture Notes

### Why Template Directory?

Zen Browser profile directories have machine-specific names (e.g., `91bgq9n8.Default (release)`). To make the dotfiles portable:

1. **profiles.ini** is symlinked (tracks active profile)
2. **profile-template/** contains the actual configuration
3. Manual copy step needed for first-time setup

This approach:
- ✅ Keeps sensitive data (cookies, history) out of dotfiles
- ✅ Makes configuration portable across machines
- ✅ Allows easy updates and version control
- ✅ Separates auto-generated files from user configuration

### What's Not Included

These files are excluded because they're machine-specific or contain sensitive data:

- `prefs.js` - Auto-generated preferences
- `cookies.sqlite` - Browsing cookies
- `places.sqlite` - History and bookmarks
- `key4.db` / `logins.json` - Stored passwords
- `extensions/` - Installed extensions
- `sessionstore-backups/` - Session data
- `cache2/` - Browser cache

## Integration with Other Dotfiles

This package follows the same patterns as other dotfiles in this repository:

- Uses GNU Stow for symlink management
- Modular package-based organization
- Template approach for machine-specific configurations
- Comprehensive documentation

See the main repository README for more details on the overall dotfiles structure.

## Resources

- [Zen Browser Official Site](https://zen-browser.app/)
- [Zen Browser GitHub](https://github.com/zen-browser/desktop)
- [Zen Theme Store](https://github.com/zen-browser/theme-store)
- [Firefox userChrome.css Documentation](https://www.userchrome.org/)
- [Transparent Zen Theme](https://www.sameerasw.com/zen)
