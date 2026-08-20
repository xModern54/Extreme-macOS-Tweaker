# com.apple.remindd — Reminders Daemon

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Process       | `remindd`                                                    |
| Binary        | `/usr/libexec/remindd`                                       |
| Signing ID    | `com.apple.remindd`                                          |
| Plist         | `/System/Library/LaunchAgents/com.apple.remindd.plist`       |
| Domain        | `gui/<uid>`                                                  |
| Owner         | Apple (system)                                               |
| Category      | consumer_apps_media                                          |
| Risk Level    | 1 — likely safe, verify after reboot                         |

## What It Does

`remindd` is the backend daemon for **Reminders.app**. It manages:

- Storing and syncing reminders (iCloud / CalDAV)
- Time-based alarm triggers (`com.apple.alarm`)
- Location-based triggers (`com.apple.locationd-events`)
- Push notifications for reminder updates (APN)
- Apple Watch sync (`nano_preferences_sync`)
- ML training for suggested reminder attributes
- User notifications for the Reminders app

It has `RunAtLoad = true` but also `EnablePressuredExit = true`, so macOS may exit it when idle and memory-pressured.

## Observed Cost

| Metric     | Value             |
|------------|-------------------|
| RSS idle   | ~20 MB            |
| CPU idle   | 0%                |
| Disk       | 0 MB/s            |
| Network    | 0 Mbps            |
| Threads    | 4                 |

## Launchd Labels

One plist, one process, seven Mach service endpoints — all inside the single `remindd` process:

| Endpoint                                                         | Purpose                          |
|------------------------------------------------------------------|----------------------------------|
| `com.apple.remindd`                                              | Main XPC service                 |
| `com.apple.remindd.userInteractive`                              | Interactive UI requests          |
| `com.apple.aps.remindd`                                          | Push notifications               |
| `com.apple.aps.remindd.dataaccess`                               | Push for DataAccess              |
| `com.apple.aps.remindd.dataaccess.dev`                           | Dev environment DataAccess       |
| `com.apple.aps.remindd.dataaccess.demo`                          | Demo environment DataAccess      |
| `com.apple.usernotifications.delegate.com.apple.reminders`       | Notification delegate            |

No system-domain counterpart.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.remindd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.remindd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.remindd"
# reboot or:
# launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.remindd.plist
```

## Test Result

**Date:** 2026-06-20

1. Bootout + disable under `gui/502` — process was already exited (PressuredExit), bootout confirmed.
2. No retry loops in logs after disable.
3. Rebooted target.
4. SSH came back in ~10 seconds.
5. Post-reboot health: network OK, DNS OK, gateway OK, memory OK.
6. `remindd` did not return after reboot — confirmed gone.
7. No reminder-related log entries at all during boot (no errors, no warnings).
8. Process count: 359 (down from 363 before this and heard disable).

**Verdict: safe to disable.** No breakage observed.

## Expected Breakage

- Reminders.app will not sync or deliver notifications.
- Time-based and location-based reminder alerts will not fire.
- Apple Watch reminder sync will not work.

None of these are relevant for a coding-focused workflow.

## Notes

- Self-contained: one plist, one process, no system-domain dependencies.
- Clean shutdown — no Mach port errors from other subsystems.
- `EnablePressuredExit` means the process may already be absent under memory pressure even without disabling it, but disabling prevents it from being launched by any trigger.
