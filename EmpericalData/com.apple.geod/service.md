# Apple GeoServices & Map Tile Engine — geod

## Basics

- **Main label:** `gui/<uid>/com.apple.geod`
- **Plist path:** `/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc/Contents/MacOS/com.apple.geod`
- **Domain:** `gui/<uid>`
- **Category:** `location_geoservices`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`geod` (GeoServices Daemon) is Apple's GeoServices framework map tile and reverse geocoding daemon:

1. **Map Tile & Reverse Geocoding Engine (`GeoServices.framework`)**: Converts GPS coordinates to street addresses, downloads Apple Maps vector tiles, and fetches points of interest (POI).
2. **System Location Data Provider**: Delivers mapping datasets to *Apple Maps*, *Weather*, *Photos* (geotagged photo albums), *Calendar*, and *Spotlight* location queries.

## What Is NOT Affected

- **Wi-Fi/GPS Physical Location Engine**: Core physical location lookup via `locationd` (`system/com.apple.locationd`), VSCode, Terminal, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates persistent GUI agent, freeing **~18.4MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.geod" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.geod"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.geod"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.geod`.
2. Process `com.apple.geod` terminated, releasing **~18.4MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `com.apple.geod` process remains stopped permanently.
   - Core Wi-Fi networking and `locationd` operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
