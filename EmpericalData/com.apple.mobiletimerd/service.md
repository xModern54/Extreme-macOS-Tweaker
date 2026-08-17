# Clock / timers / alarms — `mobiletimerd` (mobiletimerd-off)

## Basics

| Field         | Value                                              |
|---------------|----------------------------------------------------|
| Feature group | `mobiletimerd` only                                |
| Category      | Clock / timers / alarms disabled                     |
| Risk Level    | 1 — Clock consumer daemon; not needed without Clock |
| Profile       | **safe for no-Clock coding target**                 |

**Breaks:** Clock.app timers, alarms, stopwatch sessions, bedtime/sleep schedule flows, timer/alarm notifications  
**Should not break (headless verified):** SSH, login session, networking

## What It Does

Per-user **MobileTimer** backend for the Clock app and related alarm/timer surfaces:

| Endpoint | Role |
|----------|------|
| `com.apple.MobileTimer.alarmserver` | Alarms |
| `com.apple.MobileTimer.timerserver` | Timers |
| `com.apple.MobileTimer.stopwatchserver` | Stopwatch |
| `com.apple.MobileTimer.sessionserver` | Clock sessions |
| `com.apple.alarmkitservices` | AlarmKit bridge |
| `com.apple.mobiletimer.aps` | APS sync |
| `com.apple.private.alloy.mobiletimersync-idswake` | Watch / IDS sync |
| `com.apple.usernotifications.delegate.com.apple.clock` | Clock notifications |
| `com.apple.corespotlight.daemon.mobiletimer` | Spotlight indexing |

Also listens for Watch pairing (`nanoregistry.*`), wrist state (`Carousel`), bedtime diagnostics, and significant time changes.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.mobiletimerd` | gui | `mobiletimerd` | `/System/Library/LaunchAgents/com.apple.mobiletimerd.plist` |

**Binary:** `/System/Library/PrivateFrameworks/MobileTimer.framework/Executables/mobiletimerd`

**Launch:** `RunAtLoad=true`; Mach on-demand endpoints when running.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `mobiletimerd` | ~15 MB |

Idle neighbor note: `audioclocksyncd` (system) is unrelated audio clock sync — not part of this group.

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.mobiletimerd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.mobiletimerd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.mobiletimerd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **mobiletimerd-off**

**Before:** processes **286**, total RSS **4729 MB**, `mobiletimerd` running (~15 MB).

1. Bootout/disable `gui/502/com.apple.mobiletimerd` — gone immediately.
2. Reboot — SSH back ~18 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route/DNS path: default via `en0`, gateway present
   - `mobiletimerd`: **not running**; disable flag intact
   - **Delayed 25 s:** no respawn, no crash loop
   - **Unexpected neighbors:** no `mobiletimer`, `alarmkit`, `nanoregistry`, or Clock-related processes started
   - **Log storm:** 0 boot lines for mobiletimer/MobileTimer; 0 error/fail/retry
4. **After metrics:** processes **297**, total RSS **4820 MB** (~15 MB from daemon removed; remainder boot variance)

**Verdict: keep disabled on coding experimental target.**

## Expected Breakage

- Clock.app timers, alarms, stopwatch.
- Bedtime / sleep schedule clock flows.
- Timer and alarm notifications.
- Watch sync for Clock data.

**Not broken (verified headless):** SSH; no collateral respawn of clock/mobiletimer/nano neighbors.

## Notes

- User never uses Clock on this Mac.
- Distinct from `audioclocksyncd` (audio subsystem).
- Re-enable only if using Clock alarms/timers on this Mac.