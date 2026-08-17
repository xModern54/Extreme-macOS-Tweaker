# Quick Look File Preview & Thumbnailing Subsystem — com.apple.quicklook

## Basics

- **Main labels:** `gui/<uid>/com.apple.quicklook`, `gui/<uid>/com.apple.quicklook.ThumbnailsAgent`, `gui/<uid>/com.apple.quicklook.ui.helper`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.quicklook.plist`, `/System/Library/LaunchAgents/com.apple.quicklook.ThumbnailsAgent.plist`, `/System/Library/LaunchAgents/com.apple.quicklook.ui.helper.plist`
- **Binaries:** `/System/Library/Frameworks/QuickLook.framework/Resources/quicklookd.app/Contents/MacOS/quicklookd`, `/System/Library/Frameworks/QuickLookThumbnailing.framework/Support/com.apple.quicklook.ThumbnailsAgent`, `/System/Library/Frameworks/Quartz.framework/Frameworks/QuickLookUI.framework/Resources/QuickLookUIHelper.app/Contents/MacOS/QuickLookUIHelper`
- **Domain:** `gui/<uid>`
- **Category:** `ui_required_finder_quicklook`
- **Risk:** `1` (for standard coding profiles) / `2` (Conditional for users relying on Spacebar file previews in Finder)
- **Verdict:** `disable UI popups, optional keep ThumbnailsAgent`

## What It Does

The `QuickLook` subsystem manages file preview windows and thumbnail generation across Finder (`QuickLook.framework` / `QuickLookUI.framework`):

1. **Spacebar File Preview Window (`quicklookd` / `QuickLookUIService.xpc`)**: Renders preview popups when pressing `Spacebar` on files in Finder or Desktop (~70.2MB RSS RAM).
2. **Finder Icon Thumbnail Generator (`ThumbnailsAgent`)**: Generates file preview thumbnails on desktop and Finder grid views (~23.1MB RSS RAM).

## Configuration Profiles

### Option A: Complete Subsystem Disabling (Aggressive Profile)

Disables all 3 labels (`com.apple.quicklook`, `com.apple.quicklook.ThumbnailsAgent`, `com.apple.quicklook.ui.helper`). Saves **~93.3MB RAM**. Finder icon thumbnails render as generic file icons.

### Option B: Hybrid Profile (Keep Thumbnails, Disable Spacebar Popups) — CURRENT TARGET STATE

Keeps `com.apple.quicklook.ThumbnailsAgent` enabled for Finder icon previews, while disabling `com.apple.quicklook` and `com.apple.quicklook.ui.helper`. Saves **~70.2MB RAM** while preserving visual icon previews in Finder.

## Disable (Complete Disabling)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.quicklook.ThumbnailsAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.quicklook.ThumbnailsAgent"
launchctl bootout "gui/$uid/com.apple.quicklook" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.quicklook"
launchctl bootout "gui/$uid/com.apple.quicklook.ui.helper" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.quicklook.ui.helper"
```

## Enable Hybrid Profile (Keep Thumbnails Agent)

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.quicklook.ThumbnailsAgent"
launchctl bootout "gui/$uid/com.apple.quicklook" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.quicklook"
launchctl bootout "gui/$uid/com.apple.quicklook.ui.helper" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.quicklook.ui.helper"
```

## Rollback (Restore Full QuickLook Suite)

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.quicklook.ThumbnailsAgent"
launchctl enable "gui/$uid/com.apple.quicklook"
launchctl enable "gui/$uid/com.apple.quicklook.ui.helper"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. Applied Hybrid configuration: `ThumbnailsAgent` enabled, `quicklookd` / `ui.helper` disabled.
2. Verified post-reboot: `ThumbnailsAgent` operates normally for Finder icon previews.
3. Heavy `QuickLookUI` preview popups disabled, saving **~70.2MB RSS RAM**.
4. Health check script (`./scripts/health-check.sh`) passed 23/23 base checks.
5. Log audit confirmed 0 errors or retry loops.
