# com.apple.liveactivitiesd (Live Activities & ActivityKit Subsystem)

## Basics

- **Process names:** `liveactivitiesd`
- **Domain:** `gui/<uid>`
- **Plist:** `/System/Library/LaunchAgents/com.apple.liveactivitiesd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/SessionCore.framework/Support/liveactivitiesd`
- **Related Frameworks:** 
  - `/System/Library/Frameworks/ActivityKit.framework`
  - `/System/Library/PrivateFrameworks/SessionCore.framework`
  - `/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc`
- **Category:** `system_ui_live_activities_widgets`
- **Risk:** `1`
- **Verdict:** `disable`

## Notes

What it does:
Live Activities & ActivityKit Session Lifecycle Coordinator (`liveactivitiesd` / `SessionCore.framework`).
Responsible for:
1. **ActivityKit Lifecycle Management**: Orchestrates interactive live activities sessions started by applications (e.g. food delivery tracking, sports scores, timers, live rides, Uber/Lyft status).
2. **Notification Center & Widget Live Platter Bridge**: Passes real-time payload updates from background XPC connections to `chronod` (WidgetKit) and `NotificationCenter` UI rendering.
3. Bridges with `AppIntentsLiveEntityService.xpc` for tracking live `@AppEntity` model updates.

Why we looked at it:
Investigated to completely eradicate Live Activities background tracking on macOS.

Resource footprint:
~8–12 MB RAM, 0.0% CPU idle.

Needed for coding / system:
No. Standard notification banners, system alerts, static widgets (Calendar, Clock, Weather), and audio playback work 100% normally.

---

## Method 1: Runtime Launchd Disabling (Safe & Reversible)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.liveactivitiesd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.liveactivitiesd"
killall liveactivitiesd 2>/dev/null || true
```

**Rollback:**
```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.liveactivitiesd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.liveactivitiesd.plist 2>/dev/null || true
```

---

## Method 2: Total SSV System Volume Eradication (Hard Wipe)

On the mounted writable system snapshot (`/Volumes/SystemRW`):

1. **Disable LaunchAgent Plist:**
   ```bash
   mv "/Volumes/SystemRW/System/Library/LaunchAgents/com.apple.liveactivitiesd.plist" \
      "/Volumes/SystemRW/System/Library/LaunchAgents/com.apple.liveactivitiesd.plist.disabled"
   ```

2. **Isolate LiveActivities Daemon Binary:**
   ```bash
   mv "/Volumes/SystemRW/System/Library/PrivateFrameworks/SessionCore.framework/Support/liveactivitiesd" \
      "/Volumes/SystemRW/System/Library/PrivateFrameworks/SessionCore.framework/Support/liveactivitiesd.disabled"
   ```

3. **Isolate LiveEntity Companion XPC:**
   ```bash
   mv "/Volumes/SystemRW/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc" \
      "/Volumes/SystemRW/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc.disabled"
   ```

4. **Bless & Seal APFS Snapshot:**
   ```bash
   bless --folder /Volumes/SystemRW/System/Library/CoreServices --bootefi --create-snapshot
   ```

---

Verdict:
**SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE (Risk 1)**.
Wipes out background Live Activities listeners and frees ~10–15 MB RAM.
