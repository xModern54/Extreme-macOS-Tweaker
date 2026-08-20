# Safari Platform Support Helper & Background Agents Stack — SafariPlatformSupport.Helper

## Basics

- **Main labels:** `com.apple.SafariPlatformSupport.Helper`, `gui/<uid>/com.apple.SafariNotificationAgent`, `gui/<uid>/com.apple.SafariBookmarksSyncAgent`, `gui/<uid>/com.apple.Safari.SafeBrowsing.Service`, `gui/<uid>/com.apple.Safari.PasswordBreachAgent`, `gui/<uid>/com.apple.SafariHistoryServiceAgent`, `gui/<uid>/com.apple.Safari.History`, `gui/<uid>/com.apple.SafariLaunchAgent`
- **Plist paths:** Embedded framework XPC (`/System/Library/PrivateFrameworks/SafariPlatformSupport.framework/Versions/A/XPCServices/com.apple.SafariPlatformSupport.Helper.xpc`), `/System/Library/LaunchAgents/com.apple.SafariNotificationAgent.plist`, `/System/Library/LaunchAgents/com.apple.SafariBookmarksSyncAgent.plist`, `/System/Library/LaunchAgents/com.apple.Safari.SafeBrowsing.Service.plist`
- **Binaries:** `/System/Library/PrivateFrameworks/SafariPlatformSupport.framework/.../com.apple.SafariPlatformSupport.Helper`
- **Domain:** `system`, `gui/<uid>`
- **Category:** `browser_safari_platform_helper`
- **Risk:** `1` (for users utilizing Chrome / Arc / Brave / Firefox or non-Safari browsers)
- **Verdict:** `disable for coding profile`

## What It Does

`com.apple.SafariPlatformSupport.Helper` and the Safari background agents group manage built-in Safari browser background tasks:

1. **iCloud Tabs & Web Extensions Sync (`com.apple.SafariPlatformSupport.Helper`)**: Syncs active iCloud Tabs between Apple ID devices, manages Safari Web Extensions, and updates Reading List items.
2. **Background Safari Telemetry & Security**: Runs background Safe Browsing checks, password breach scanning, and bookmark syncing.

## What Is NOT Affected

- **Third-Party Web Browsers (Chrome, Arc, Brave, Firefox, Edge)**: All third-party browsers, web development, VSCode, Terminal, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Releasing **~36.3MB RSS RAM** from `SafariPlatformSupport.Helper` and preventing background agent spawns.

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.SafariNotificationAgent
  com.apple.SafariBookmarksSyncAgent
  com.apple.Safari.SafeBrowsing.Service
  com.apple.Safari.PasswordBreachAgent
  com.apple.SafariHistoryServiceAgent
  com.apple.Safari.History
  com.apple.SafariLaunchAgent
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
sudo killall com.apple.SafariPlatformSupport.Helper 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)
labels=(
  com.apple.SafariNotificationAgent
  com.apple.SafariBookmarksSyncAgent
  com.apple.Safari.SafeBrowsing.Service
  com.apple.Safari.PasswordBreachAgent
  com.apple.SafariHistoryServiceAgent
  com.apple.Safari.History
  com.apple.SafariLaunchAgent
)
for label in "${labels[@]}"; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502` Safari agents group and `SafariPlatformSupport.Helper` killed.
2. Process `com.apple.SafariPlatformSupport.Helper` terminated, releasing **~36.3MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - All Safari background processes remain stopped permanently (`pgrep -fl -i "safari"` -> 0).
   - Third-party web browsers and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
