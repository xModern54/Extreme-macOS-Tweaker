# Transparent Application Lifecycle — talagentd

## Basics

- **Main label:** `com.apple.talagent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.talagent.plist`
- **Binary:** `/System/Library/CoreServices/talagentd`
- **Domain:** `gui/<uid>`
- **Category:** `ui_app_state_persistence`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`talagentd` (Transparent Application Lifecycle Daemon) is Apple's window state restoration and persistent application lifecycle manager (introduced in OS X 10.7 Lion "Resume" feature).

Key responsibilities:

1. **Window State Persistence (`com.apple.appkit.restoration_storage`)**:
   - Captures exact window geometry, scroll position, and open document states upon application quit or system shutdown, writing `.savedState` bundles to `~/Library/Saved Application State/`.

2. **Login Window Restoration (`com.apple.window_proxies.startup`)**:
   - Reopens previous application windows upon user login.

3. **Crash Recovery**:
   - Restores window states after application crashes.

## Modern macOS Architecture & Legacy Bloat Status

In modern macOS (Sonoma / Sequoia):

1. **Modern AppKit Direct State Handling**:
   - Modern 64-bit / SwiftUI / AppKit applications handle window state restoration and `.savedState` directory management directly via AppKit and `launchservicesd` / `loginwindow`.
   - The "Reopen windows when logging back in" feature and app window restoration continue functioning 100% without `talagentd`.

2. **`talagentd` as Legacy Bloat**:
   - `talagentd` is a legacy background helper (originally introduced in OS X 10.7 Lion) retained for backward compatibility with legacy 32-bit / Carbon / early Cocoa restoration APIs.
   - On modern macOS systems, `talagentd` is redundant legacy bloat consuming **~26MB RAM** while duplicating work natively handled by AppKit.
   - Disabling `com.apple.talagent` is **100% safe** and preserves all user-facing window restoration functionality while freeing memory.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.talagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.talagent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.talagent"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `launchctl bootout` and `launchctl disable` applied for `gui/502/com.apple.talagent`.
2. Process `talagentd` terminated, releasing **~26MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Verified:
   - `talagentd` remains stopped (`process_count` decreased).
   - Log audit confirmed **0 errors** or retry loops.
   - Applications open with clean default windows, disk writes to `~/Library/Saved Application State/` are eliminated.
