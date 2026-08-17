# Wallpaper & Desktop Background Architecture

## Basics

- **Main labels:** `com.apple.wallpaper.agent`, `com.apple.wallpaper.export`
- **Processes:** `WallpaperAgent`, `WallpaperAerialsExtension`, `wallpaperexportd`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `ui_desktop_wallpaper`
- **Risk:** `3 (do NOT disable WallpaperAgent; disable wallpaperexportd & switch to static wallpaper)`
- **Verdict:** `Keep WallpaperAgent for static wallpapers; disable wallpaperexportd; select static PNG/JPG in Settings to stop WallpaperAerialsExtension (saves ~140MB RAM)`

## What It Does

1. **`com.apple.wallpaper.agent` (`WallpaperAgent`)**:
   - Primary macOS Desktop wallpaper rendering agent (`/System/Library/CoreServices/WallpaperAgent.app`).
   - **CRITICAL**: Responsible for rendering static desktop background images (`.png`/`.jpg`). Disabling `WallpaperAgent` turns the desktop background into a solid black/grey void. Must remain enabled for normal GUI operation.

2. **`WallpaperAerialsExtension` (`com.apple.wallpaper.extension.aerials`)**:
   - ExtensionKit extension responsible for downloading, decoding, and playing 4K Aerial video wallpapers and dynamic screen savers (macOS Sonoma / Sequoia feature).
   - Consumes **~75MB to 140MB RSS**.
   - Spawns dynamically under `WallpaperAgent` when a video/Aerial wallpaper is chosen in System Settings. Switching desktop wallpaper to a static image suppresses Aerial video decoding.

3. **`system/com.apple.wallpaper.export` (`wallpaperexportd`)**:
   - Background daemon for exporting wallpaper thumbnail previews (`/usr/libexec/wallpaperexportd`).
   - Safe to disable (`system/com.apple.wallpaper.export`).

## Disable & Optimization Commands

Disable wallpaper export daemon:

```bash
sudo launchctl bootout system/com.apple.wallpaper.export
sudo launchctl disable system/com.apple.wallpaper.export
```

**Do NOT disable:** `gui/<uid>/com.apple.wallpaper.agent`

## Rollback

```bash
sudo launchctl enable system/com.apple.wallpaper.export
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. **Core Wallpaper Functionality (CONFIRMED WORKING)**:
   - Leaving ONLY `com.apple.wallpaper.agent` (`WallpaperAgent`) is **100% sufficient** for standard wallpaper usage.
   - Setting static desktop pictures works.
   - Switching wallpapers via system settings/menu works.
   - Downloading standard wallpaper assets via Apple menu works.
   - Desktop rendering is fully intact.

2. **Aerial / Dynamic Video Screensavers**:
   - Animated Aerial video wallpapers / dynamic video screensavers are disabled / suppressed when video rendering extension is not used.

3. **Conclusion**:
   - For a coding-focused workflow, **only `com.apple.wallpaper.agent` is required**. All secondary export and background video daemons can be disabled without breaking standard desktop wallpapers.
