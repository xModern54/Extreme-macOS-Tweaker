# Finder Sidebar & Shared File Lists Engine — sharedfilelistd

## Basics

- **Main labels:** `gui/<uid>/com.apple.coreservices.sharedfilelistd`, `system/com.apple.coreservices.sharedfilelistd`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.coreservices.sharedfilelistd.plist`, `/System/Library/LaunchDaemons/com.apple.coreservices.sharedfilelistd.plist`
- **Binary:** `/System/Library/CoreServices/sharedfilelistd`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `ui_recent_items_history`
- **Risk:** `4` (Critical System UI Component — Controls Finder Sidebar Favorites)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`sharedfilelistd` (Shared File List Daemon) is Apple's core manager for Finder Sidebar Favorites, Shared File Lists, and Recent Items across macOS:

1. **Finder Sidebar (Избранное / Favorites)**: Resolves and populates the left sidebar in Finder (`Favorites`: Desktop, Documents, Downloads, Recents, Tags).
2. **Apple Menu Recent Items ( -> Recent Items)**: Tracks opened document and application paths for the global Apple menu history list.
3. **Open/Save Dialog Recents (`Cmd+O` / `Cmd+S`)**: Populates recent file lists in system open/save file pickers.

## Why It Must Remain Enabled

- **CRITICAL**: Disabling `sharedfilelistd` **completely clears the Finder left sidebar** (Favorites, Documents, Downloads, Desktop, and Recents disappear entirely, leaving a blank empty sidebar).

## Rollback / Enable Command

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.coreservices.sharedfilelistd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.coreservices.sharedfilelistd.plist
sudo launchctl enable system/com.apple.coreservices.sharedfilelistd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.coreservices.sharedfilelistd.plist
killall Finder
```

## Status

**RESTORED AND KEPT ENABLED FOR FINDER SIDEBAR.**
