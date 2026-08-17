# GeoServices Cache-Delete Bridge

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `geodMachServiceBridge` — GeoServices CacheDelete integration  |
| Category      | `core_macos` (GeoServices plumbing)                            |
| Risk Level    | 1 — small helper; not required for coding workflow               |

## What It Does

Thin LaunchAgent that exposes `com.apple.geod.cachedelete` so the system CacheDelete service can purge GeoServices/map tile caches. It does not provide location fixes itself; it is plumbing between `geod` caches and cache management.

Binary: `/System/Library/PrivateFrameworks/GeoServices.framework/geodMachServiceBridge`

## Observed Cost (before disable)

| Process               | Domain | RSS    |
|-----------------------|--------|--------|
| `geodMachServiceBridge` | gui  | ~4.5 MB |

## Launchd Labels

| Label                         | Plist                                                            | Domain |
|-------------------------------|------------------------------------------------------------------|--------|
| `com.apple.geodMachServiceBridge` | `/System/Library/LaunchAgents/com.apple.geodMachServiceBridge.plist` | gui |

### Endpoints

| Endpoint                   | Role |
|----------------------------|------|
| `com.apple.geod.cachedelete` | CacheDelete Mach service for GeoServices |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.geodMachServiceBridge" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.geodMachServiceBridge"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.geodMachServiceBridge"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Bootout `gui/502/com.apple.geodMachServiceBridge` — process disappeared immediately.
2. No errors in logs after bootout.
3. Disabled label — confirmed in `launchctl print-disabled`.
4. Rebooted target; SSH back in ~22 seconds.
5. Post-reboot health: gateway/interface OK.
6. `geodMachServiceBridge` did not return; label remains disabled.
7. `locationd`, all `geod` instances, `CoreLocationAgent` still running.
8. No geodMach/cachedelete errors in boot logs.
9. Process count: 351 (~4.5 MB RSS saved).

**Verdict: safe to disable on coding experimental target.**

## Expected Breakage

- Automatic CacheDelete integration for GeoServices caches may be reduced; manual cache cleanup still possible under `~/Library/Caches/GeoServices`.
- No observed impact on Wi-Fi, SSH, timezone, or active `geod` operation.

## Notes

- Part of location stack research in `services/com.apple.locationd/service.md`.
- Disable before experimenting with `CoreLocationAgent` or `geod` clients.