# com.apple.accessibility.heard — Hearing Accessibility Daemon

## Basics

| Field         | Value                                                                        |
|---------------|------------------------------------------------------------------------------|
| Process       | `heard`                                                                      |
| Binary        | `/System/Library/PrivateFrameworks/HearingCore.framework/heard`              |
| Signing ID    | `com.apple.accessibility.heard`                                              |
| Domain        | `gui/<uid>`                                                                  |
| Owner         | Apple (system)                                                               |
| Category      | accessibility                                                                |
| Risk Level    | 1 — likely safe, verify after reboot                                         |

## What It Does

`heard` is the Hearing accessibility daemon. It manages:

- Made for iPhone (MFi) hearing device pairing and streaming
- Live Listen (using AirPods/hearing aids as a remote mic)
- Sound Recognition (alerting for doorbells, alarms, etc.)
- Headphone Accommodations (tuning audio for hearing needs)
- Background Sounds (playing ambient noise for focus/masking)
- HearingModeService Mach endpoint

It runs under the user's GUI session and registers several Mach services:

| MachService / Endpoint                     | State at boot |
|--------------------------------------------|---------------|
| `com.apple.accessibility.heard`            | Active        |
| `com.apple.aps.heard`                      | Demand        |
| `com.apple.private.alloy.hearing-idswake`  | Active        |
| `com.apple.HearingModeService`             | Active        |

No system-domain counterpart was found.

## Observed Cost

| Metric     | Value             |
|------------|-------------------|
| RSS idle   | 30–40 MB          |
| CPU idle   | 0%                |
| Disk       | 0 MB/s            |
| Network    | 0 Mbps            |
| Threads    | 4                 |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.accessibility.heard" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.accessibility.heard"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.accessibility.heard"
# reboot or:
# launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.accessibility.heard.plist
```

## Test Result

**Date:** 2026-06-20

1. Bootout + disable under `gui/502` — process disappeared immediately.
2. No retry loops in logs after disable.
3. Rebooted target.
4. SSH came back in ~10 seconds.
5. Post-reboot health: network OK, DNS OK, gateway OK, memory OK.
6. `heard` did not return after reboot — confirmed gone.
7. No hearing-related log entries at all during boot (no errors, no warnings).
8. Process count: 363 (consistent with previous baselines).

**Verdict: safe to disable.** No breakage observed.

## Expected Breakage

- Made for iPhone hearing devices will not connect.
- Live Listen will not work.
- Sound Recognition alerts will not fire.
- Headphone Accommodations will be unavailable.
- Background Sounds feature will be unavailable.

None of these are relevant for a coding-focused workflow.

## Notes

- Only exists in user GUI domain, no system-level daemon.
- Clean shutdown — no Mach port errors from other subsystems trying to reach hearing endpoints.
- Very low risk; the feature is entirely self-contained.
- All four Mach services (`com.apple.accessibility.heard`, `com.apple.aps.heard`, `com.apple.private.alloy.hearing-idswake`, `com.apple.usernotifications.delegate.com.apple.SoundDetectionNotifications`) are endpoints **inside the single `heard` process**, not separate launchd jobs. Disabling the one label kills all of them.
- `com.apple.HearingModeService` looks hearing-related but is actually registered by **`audioaccessoryd`** (`com.apple.BTServer.cloudpairing`), a broader Bluetooth cloud pairing / audio accessory daemon (~29 MB). It should NOT be disabled as part of this group — it handles AirPods, BT audio accessories, and BT cloud services. It is a separate research candidate under the Bluetooth/audio accessory category.
