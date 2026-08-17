# User Notifications — Core Stack

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Notification core: `usernoted` + `usernotificationsd` + `notificationcenterui.agent` + `apsd` |
| Category      | `ui_required` / consumer notifications                         |
| Risk Level    | 3 — disables all user notifications and push delivery; GUI Mac |

## What It Does

macOS notification stack in four layers:

| Layer | Label / process | Role |
|-------|-----------------|------|
| UI | `com.apple.notificationcenterui.agent` → `NotificationCenter` | Banners, Notification Center panel, `widget-observation` |
| Legacy/core broker | `com.apple.usernoted` → `usernoted` | KeepAlive central UN server; `usernoted.*` Mach services, remote notification service |
| Modern server | `com.apple.usernotificationsd` → `usernotificationsd` | BulletinBoard, settings-vendor, alert-coordination, IDS-wake |
| Push infra | `com.apple.apsd` → `apsd` | Apple Push Service — remote push to apps and system agents |

Not required for SSH, compilers, Git, or headless coding.

## Observed Cost (before disable)

| Process | Domain | RSS |
|---------|--------|-----|
| `NotificationCenter` | gui | ~58 MB |
| `usernoted` | gui | ~22 MB |
| `usernotificationsd` | gui | ~16 MB |
| `apsd` | system | ~27 MB |
| **Total** | | **~123 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.notificationcenterui.agent` | `/System/Library/LaunchAgents/com.apple.notificationcenterui.plist` | gui |
| `com.apple.usernoted` | `/System/Library/LaunchAgents/com.apple.usernoted.plist` | gui |
| `com.apple.usernotificationsd` | `/System/Library/LaunchAgents/com.apple.usernotificationsd.plist` | gui |
| `com.apple.apsd` | `/System/Library/LaunchDaemons/com.apple.apsd.plist` | system |

### Key Mach endpoints

**usernoted:** `com.apple.usernoted.client`, `com.apple.usernoted.notificationcenter`, `com.apple.usernoted.push`, `com.apple.usernotifications.usernotificationservice`

**usernotificationsd:** `com.apple.usernotifications.coreservice`, `com.apple.bulletinboard.settingspersistenceconnection`, `com.apple.usernotifications.settings-vendor`

**notificationcenterui:** `com.apple.notificationcenterui.main`, `com.apple.notificationcenterui.menu`, `com.apple.widget-observation`

**apsd:** `com.apple.apsd`

## Disable

```bash
uid=$(id -u)
labels_gui=(
  com.apple.notificationcenterui.agent
  com.apple.usernoted
  com.apple.usernotificationsd
)
for label in "${labels_gui[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
sudo launchctl bootout system/com.apple.apsd 2>/dev/null || true
sudo launchctl disable system/com.apple.apsd
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.notificationcenterui.agent"
launchctl enable "gui/$uid/com.apple.usernoted"
launchctl enable "gui/$uid/com.apple.usernotificationsd"
sudo launchctl enable system/com.apple.apsd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all four processes running (~123 MB RSS total).
2. Bootout — all processes disappeared immediately.
3. 30-second delayed check — none returned.
4. Disabled flags confirmed in `launchctl print-disabled` (gui + system).
5. Reboot — SSH back ~18 seconds.
6. Post-reboot: no `NotificationCenter`, `usernoted`, `usernotificationsd`, or `apsd` processes.
7. 45-second delayed post-reboot check — still absent.
8. Process count: 333 → 317 (−16).
9. Health: gateway `192.168.1.1` via `en0`, DNS OK, memory pressure OK.
10. Boot logs: no obvious repeated notification-stack failure loops.

**Verdict: safe to disable on coding experimental target. All user notifications and push delivery stopped.**

### User-confirmed UI (2026-06-20)

- Menu bar click on the former Notification Center area: **no response** (panel does not open).
- System Settings → Notifications tab: **does not open** at all.
- Confirms full notification UI stack removal on interactive GUI session.

## Expected Breakage

- No notification banners, Notification Center panel, or delivered alerts.
- No Apple Push Service — remote push to apps and system agents stops.
- Apps using `UserNotifications` framework get no delivery path.
- System alerts that relied on UN (security prompts visibility, update nags) may be silent.
- `NotificationCenter` `widget-observation` endpoint gone ( `chronod` was already disabled).
- Disabling `apsd` may cause push-retry log noise from Apple services still expecting push.

No impact on SSH, Wi-Fi, gateway, or boot stability observed.

## Notes

- Part of notification "whitening" experiment; Group B (peripheral delegates) tested separately.
- `donotdisturbd` was already disabled earlier — Focus/DND layer already gone.
- Do **not** disable `notifyd` or `distnoted` — lower-level pub/sub, not this stack.
- `controlcenter` and `Dock.agent` still running; they expose notification-related Mach endpoints but are GUI infrastructure (deferred).