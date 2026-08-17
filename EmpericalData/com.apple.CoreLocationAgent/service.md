# CoreLocation Desktop Agent

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `CoreLocationAgent` — desktop location permission / agent UI   |
| Category      | `ui_required` / `core_macos`                                   |
| Risk Level    | 3 — may affect location permission prompts; not boot-critical  |

## What It Does

Per-user LaunchAgent that exposes `com.apple.CoreLocation.agent` and handles desktop-side CoreLocation plumbing, including location permission UI and agent callbacks from `locationd`.

Binary: `/System/Library/CoreServices/CoreLocationAgent.app/Contents/MacOS/CoreLocationAgent`

This is **not** the same as `locationd`. `locationd` continues to run without this agent.

## Observed Cost (before disable)

| Process             | Domain | RSS    |
|---------------------|--------|--------|
| `CoreLocationAgent` | gui    | ~46 MB |

Largest single process in the location stack on the experimental target.

## Launchd Labels

| Label                         | Plist                                                            | Domain |
|-------------------------------|------------------------------------------------------------------|--------|
| `com.apple.CoreLocationAgent` | `/System/Library/LaunchAgents/com.apple.CoreLocationAgent.plist` | gui    |

### Endpoints

| Endpoint                      | Role |
|-------------------------------|------|
| `com.apple.CoreLocation.agent`| Desktop agent surface for CoreLocation / TCC flows |

Talks to `locationd` via `com.apple.locationd.desktop.agent` (on the `locationd` side).

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.CoreLocationAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.CoreLocationAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.CoreLocationAgent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Bootout `gui/502/com.apple.CoreLocationAgent` — ~46 MB process disappeared immediately.
2. No errors in logs after bootout.
3. 30-second delayed check — process did not return.
4. Disabled label — confirmed in `launchctl print-disabled`.
5. Rebooted target; SSH back in ~22 seconds.
6. Post-reboot health: SSH, login, Wi-Fi gateway, DNS, memory pressure OK.
7. `CoreLocationAgent` did not return after reboot.
8. `locationd`, all three `geod` instances, `WiFiAgent`, `airportd`, `timed` still running.
9. No locationd/CoreLocation errors in boot logs.
10. Process count: 350 (down from ~357 at start of location experiments).

**Verdict: safe to disable on headless/coding experimental target.** No breakage observed for SSH, networking, or `locationd` core.

## Expected Breakage

- Location permission dialogs may not appear for apps requesting geolocation.
- Apps depending on `CoreLocation.agent` Mach endpoint may fail to register or show UI flows.
- Maps/Weather/any app needing interactive location consent on this Mac may misbehave.

Does **not** stop `locationd`, Wi-Fi regulatory domain logic, or automatic timezone sources by itself.

## Notes

- After disable, `ospredictiond` still holds `com.apple.geod` lookup; user/502 `geod` instance remains (~17 MB).
- Re-enable before using consumer apps that need location permission UI.
- See `services/com.apple.locationd/service.md` for full stack research and geod client tracing.