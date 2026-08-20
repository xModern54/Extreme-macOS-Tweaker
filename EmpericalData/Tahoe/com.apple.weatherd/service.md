# Location Idle Satellites — Weather / Maps Push / Nav

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Weather, Maps push, and navigation on-demand daemons           |
| Category      | `icloud_account_apple_ecosystem` / `photos_media_analysis`     |
| Risk Level    | 1 — idle on coding target; disables consumer map/weather features |

## What It Does

Three separate on-demand LaunchAgents that wake for Apple consumer geo features:

- **weatherd** (`com.apple.weatherd`) — Weather app daemon, predicted locations, WeatherKit, push notifications
- **mapspushd** (`com.apple.Maps.mapspushd`) — Maps push/sync, GeoServices media API, shared trip updates
- **navd** (`com.apple.navd`) — Navigation daemon; KeepAlive when `~/Library/Caches/GeoServices/Navd/working` exists

All are clients of the broader GeoServices/location ecosystem but are **not** part of the `locationd` core. They were idle (not running) before disable on the experimental target.

## Observed Cost (before disable)

| Process / label              | State at capture | RSS |
|------------------------------|------------------|-----|
| `weatherd`                   | not running      | 0   |
| `mapspushd`                  | not running      | 0   |
| `navd`                       | not running      | 0   |

No active memory savings at idle; benefit is preventing future on-demand wakeups and background geo work.

## Launchd Labels

| Label                      | Plist                                                         | Domain |
|----------------------------|---------------------------------------------------------------|--------|
| `com.apple.weatherd`       | `/System/Library/LaunchAgents/com.apple.weatherd.plist`       | gui    |
| `com.apple.Maps.mapspushd` | `/System/Library/LaunchAgents/com.apple.Maps.pushdaemon.plist` | gui  |
| `com.apple.navd`           | `/System/Library/LaunchAgents/com.apple.navd.plist`           | gui    |

### Notable endpoints

```text
weatherd:     com.apple.weatherd.predicted-locations, com.apple.weatherd.weatherkit, com.apple.aps.weather
mapspushd:    com.apple.Maps.mapspushd.geoservices, com.apple.Maps.xpc.MediaAPI
navd:         com.apple.navd
```

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.weatherd
  com.apple.Maps.mapspushd
  com.apple.navd
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.weatherd com.apple.Maps.mapspushd com.apple.navd; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all three labels `not running`, 0 RSS.
2. Bootout all 3 gui labels — no processes to remove; logs empty.
3. Disabled all 3 labels — confirmed in `launchctl print-disabled`.
4. Rebooted target; SSH back in ~22 seconds.
5. Post-reboot: network, DNS, gateway OK; memory pressure normal.
6. No weatherd/mapspushd/navd processes after reboot.
7. No related log errors during boot window.
8. Process count: 354.
9. `locationd`, `geod`, `CoreLocationAgent` unaffected.

**Verdict: safe to disable on coding experimental target.**

## Expected Breakage

- Weather app widgets/notifications/background updates on this Mac.
- Maps push notifications and shared-trip features.
- Turn-by-turn navigation daemon (`navd`) will not start.

Does not affect SSH, Wi-Fi, timezone, or `locationd` core.

## Notes

- Grouped as one feature bundle because all three are idle consumer geo satellites with the same risk profile.
- See also `services/com.apple.locationd/service.md` for the core location stack research.