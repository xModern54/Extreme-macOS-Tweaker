# OS Intelligence Prediction Daemon

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `ospredictiond` — OSIntelligence inactivity / last-lock / AutoLPM predictions |
| Category      | `routine_proactive_intelligence` / `analytics_telemetry`       |
| Risk Level    | 2 — disables power-behavior predictions; not boot-critical     |

## What It Does

System LaunchDaemon from the **OSIntelligence** framework. Predicts user behavior to optimize power and background scheduling:

- **Inactivity prediction** — when the user is likely to become inactive (`_OSInactivityPredictor`)
- **Last-lock prediction** — when the screen is likely to lock (`_OSLastLockPredictor`, ML models)
- **Auto Low Power Mode** — `_OSIAutoLPMHandler`, can engage LPM based on typical location and usage patterns
- **OSIntelligence notifications** — inactivity-related user notifications (on demand)

Data sources: Biome streams (activity, screen lock, battery, timezone, now playing), `locationd`/`geod` (micro-location visits), calendar (`calaccessd`), CoreDuet context events, `powerd` / `powerexperienced`.

Not required for SSH, coding tools, Wi-Fi, or `locationd` core operation.

## Observed Cost (before disable)

| Process          | Domain | RSS     |
|------------------|--------|---------|
| `ospredictiond`  | system | ~12.5 MB |

Jetsam soft limit: 50 MB.

## Launchd Labels

| Label                   | Plist                                                         | Domain |
|-------------------------|---------------------------------------------------------------|--------|
| `com.apple.ospredictiond` | `/System/Library/LaunchDaemons/com.apple.ospredictiond.plist` | system |

### MachServices (endpoints)

| Endpoint                                                              | Role |
|-----------------------------------------------------------------------|------|
| `com.apple.OSIntelligence`                                            | Main OSIntelligence XPC API |
| `com.apple.OSIntelligence.lastlock`                                   | Last-lock prediction |
| `com.apple.OSIntelligence.battery`                                      | Battery-related predictions (demand) |
| `com.apple.OSIntelligence.charging`                                     | Charging-related predictions (demand) |
| `com.apple.usernotifications.delegate.com.apple.osintelligence.notifications` | Inactivity notifications |

### LaunchEvents

```text
com.apple.coreduetcontext.client_event_stream — client id osintelligence.iblm.contextstore-registration
com.apple.notifyd — console_mode_changed, kPLTaskingStartNotificationGlobal
com.apple.xpc.activity — evaluateModelType (screen sleep), inactivitybackup (every 345600s)
```

### Notable Mach lookups (clients of other services)

```text
com.apple.geod
com.apple.locationd.synchronous
com.apple.locationd.activity
com.apple.coreduetd.context
com.apple.routined.registration
com.apple.biome.*
com.apple.powerd.lowpowermode
com.apple.duetactivityscheduler
```

`routined` and `coreduetd` were already disabled on the target; `ospredictiond` still operated via Biome and location APIs independently.

## Relationship to geod

`ospredictiond` holds direct `com.apple.geod` and `locationd` lookups for typical-location and micro-location visit signals. Disabling it removes one geo client, but **user/502 `geod` may remain** if other GUI clients (e.g. `NotificationCenter`) still hold the XPC service.

## Disable

```bash
sudo launchctl bootout system/com.apple.ospredictiond 2>/dev/null || true
sudo launchctl disable system/com.apple.ospredictiond
```

## Rollback

```bash
sudo launchctl enable system/com.apple.ospredictiond
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `ospredictiond` running ~12.5 MB RSS (pid 543, root).
2. Bootout `system/com.apple.ospredictiond` — process disappeared immediately.
3. No errors in logs after bootout.
4. 30-second delayed check — process did not return.
5. Disabled label — confirmed in `launchctl print-disabled system`.
6. Rebooted target; SSH back in ~19 seconds.
7. Post-reboot health: SSH, login, gateway, DNS, memory pressure OK.
8. `ospredictiond` did not return; label remains disabled.
9. `locationd`, all three `geod` instances, `powerexperienced` still running.
10. No osprediction/OSIntelligence errors in boot logs.
11. Process count: 350.

**Verdict: safe to disable on coding experimental target.** No breakage observed for SSH, networking, or `locationd` core.

**Note:** user/502 `geod` (~17 MB) still present after disable — held by other clients, not only `ospredictiond`.

## Expected Breakage

- Automatic Low Power Mode predictions based on usage/location patterns.
- Inactivity and last-lock prediction features used by OSIntelligence / power mitigations.
- OSIntelligence inactivity notifications.
- Some `powerexperienced` mitigation paths that consult `OSIntelligence` endpoints.

Does not stop `locationd`, Wi-Fi, timezone (`timed`), or SSH.

## Notes

- Related to but separate from the disabled `routined` / CoreDuet group — overlapping data sources, different daemon.
- `powerexperienced` listens for `com.apple.osintelligence.iblm.mitigationchanged`.
- Prime research context: `services/com.apple.locationd/service.md` (geod client tracing).