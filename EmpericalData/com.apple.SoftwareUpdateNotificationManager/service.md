# User Notifications — Peripheral Delegates

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Notification peripherals: legacy UNC, iCloud, family, Safari/web push, hardware/USB alerts, diagnostics push |
| Category      | `ui_required` / consumer notifications                         |
| Risk Level    | 1–2 — mostly idle on target; not boot-critical                 |

## What It Does

Feature-specific notification agents and legacy UNC plumbing. These register `usernotifications.delegate` or `usernotificationcenter.matching` handlers — they deliver or react to alerts for specific Apple features, not the core UN stack (disabled separately in Group A).

| Label | Process | Role |
|-------|---------|------|
| `com.apple.SoftwareUpdateNotificationManager` | `SoftwareUpdateNotificationManager` | macOS update available / insufficient space alerts |
| `com.apple.UserNotificationCenterAgent` | `UserNotificationCenter` | Legacy per-user UNC alerts |
| `com.apple.UserNotificationCenterAgent-LoginWindow` | `UserNotificationCenter -loginwindow` | Legacy UNC at login window |
| `com.apple.UserNotificationCenter` | `uncd` | Legacy system UNC daemon |
| `com.apple.iCloudNotificationAgent` | `iCloudNotificationAgent` | iCloud notification plumbing |
| `com.apple.iCloudUserNotificationsd` | `iCloudUserNotificationsd` | iCloud user notification delegate |
| `com.apple.familynotificationd` | `familynotificationd` | Family sharing alerts |
| `com.apple.noticeboard.agent` | `nbagent` | Noticeboard alerts |
| `com.apple.SafariNotificationAgent` | `SafariNotificationAgent` | Safari web notification events |
| `com.apple.webkit.webpushd` | `webpushd` | Web Push service (Safari) |
| `com.apple.security.keychain-circle-notification` | Keychain Circle Notification | iCloud Keychain circle approval UI |
| `com.apple.usbnotificationagent` | `usbnotificationagent` | USB device attach alerts |
| `com.apple.MENotificationService` | `MENotificationAgent` | Media Extension notifications |
| `com.apple.diagnosticspushd` | `diagnosticspushd` | Diagnostics push relay |
| `com.apple.AOSPushRelay` | `AOSPushRelay` | AOS push relay |
| `com.apple.mobile.notification_proxy` | `notification_proxy` | iOS device notification proxy |

Tested after Group A (core stack) was already disabled.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `SoftwareUpdateNotificationManager` | running | ~43 MB |
| All other Group B agents | idle | 0 |

## Launchd Labels

14 gui + 2 system labels (16 total). Plists under `/System/Library/LaunchAgents/` and `/System/Library/LaunchDaemons/` except Safari/webpush Cryptex paths.

## Disable

```bash
uid=$(id -u)
labels_gui=(
  com.apple.SoftwareUpdateNotificationManager
  com.apple.UserNotificationCenterAgent
  com.apple.UserNotificationCenterAgent-LoginWindow
  com.apple.iCloudNotificationAgent
  com.apple.iCloudUserNotificationsd
  com.apple.familynotificationd
  com.apple.noticeboard.agent
  com.apple.SafariNotificationAgent
  com.apple.webkit.webpushd
  com.apple.security.keychain-circle-notification
  com.apple.usbnotificationagent
  com.apple.MENotificationService
  com.apple.diagnosticspushd
  com.apple.AOSPushRelay
)
for label in "${labels_gui[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
labels_system=(
  com.apple.UserNotificationCenter
  com.apple.mobile.notification_proxy
)
for label in "${labels_system[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.SoftwareUpdateNotificationManager com.apple.UserNotificationCenterAgent com.apple.UserNotificationCenterAgent-LoginWindow com.apple.iCloudNotificationAgent com.apple.iCloudUserNotificationsd com.apple.familynotificationd com.apple.noticeboard.agent com.apple.SafariNotificationAgent com.apple.webkit.webpushd com.apple.security.keychain-circle-notification com.apple.usbnotificationagent com.apple.MENotificationService com.apple.diagnosticspushd com.apple.AOSPushRelay; do
  launchctl enable "gui/$uid/$label"
done
sudo launchctl enable system/com.apple.UserNotificationCenter
sudo launchctl enable system/com.apple.mobile.notification_proxy
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: only `SoftwareUpdateNotificationManager` running (~43 MB); 15 other labels idle.
2. Bootout — SUM process disappeared; idle labels unchanged.
3. 30-second delayed check — no Group B processes returned.
4. All 16 labels confirmed disabled.
5. Reboot — SSH back ~23 seconds.
6. Post-reboot: no Group A or Group B notification processes.
7. Group A disable flags still intact after reboot.
8. 45-second delayed check — still clean.
9. Process count: 333 → 316 (−17 total vs baseline).
10. Health: gateway, Wi-Fi, memory pressure OK.

**Verdict: safe to disable on coding experimental target. Completes notification peripheral layer after Group A core disable.**

### User-confirmed UI (2026-06-20)

Together with Group A: Notification Center menu bar control is dead; Settings → Notifications pane won't open. Full end-user notification surface removed.

## Expected Breakage

- No Software Update notification alerts (updates may still download silently).
- No legacy UNC alerts, iCloud/Family/Safari web push notification handlers.
- No Keychain circle approval popups, USB attach alerts, diagnostics push relay.
- No iOS notification proxy on this Mac.

Combined with Group A: notification system fully whitened except `controlcenter`/`Dock` endpoints and `notifyd`/`distnoted` infrastructure.

## Notes

- Tested in sequence after Group A (`com.apple.usernoted` card); separate commits.
- `donotdisturbd` was already disabled before this experiment.
- Many other disabled services (`imagent`, `remindd`, `chronod`, etc.) had their own notification delegates — already gone.