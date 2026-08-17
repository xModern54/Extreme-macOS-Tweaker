# Location Stack — Research (Read-Only)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | Core Location (`locationd` + GeoServices + permission agents)       |
| Category      | `core_macos` / `networking` / `ui_required` (mixed)                   |
| Risk Level    | **4** for `locationd`; **2–3** for satellites; see matrix below     |
| Status        | **Core hub disabled** on target — validated, borderline for hard-opt  |

## Architecture Overview

The Location layer is not one daemon. It is a hub-and-spoke stack:

```text
                    ┌─────────────────────────────────────┐
                    │  locationd (system, _locationd)    │
                    │  WiFi/BT/motion/GPS fusion hub     │
                    └──────────────┬──────────────────────┘
                                   │ Mach/XPC clients
         ┌─────────────────────────┼─────────────────────────┐
         ▼                         ▼                         ▼
 CoreLocationAgent            geod (per-user XPC)      locationaccessstored
 (gui, permission UI)         (GeoServices/maps)       (demand, TCC store)
         │                         │
         │                    geodMachServiceBridge
         │                    (cache-delete bridge)
         ▼
 WiFiAgent, airportd, timed, bluetoothd, nearbyd, milod, ospredictiond, …
```

**Find My** was a separate client layer (already disabled). `locationd` does not depend on Find My clients.

**routined** was a client of `com.apple.locationd.routine` (already disabled). The endpoint remains registered on `locationd`; no errors observed.

## Observed Cost (2026-06-20, post–Find My disable)

| Process / service              | Domain        | UID   | RSS      | Always on? |
|--------------------------------|---------------|-------|----------|------------|
| `CoreLocationAgent`            | gui/502       | 502   | ~46 MB   | yes        |
| `locationd`                    | system        | 205   | ~28 MB   | yes        |
| `com.apple.geod`               | user/205      | 205   | ~19 MB   | yes*       |
| `com.apple.geod`               | user/262      | 262   | ~19 MB   | yes*       |
| `com.apple.geod`               | user/502      | 502   | ~17 MB   | yes*       |
| `geodMachServiceBridge`        | gui/502       | 502   | ~4.5 MB  | yes        |
| `locationaccessstored`         | gui/502       | 502   | 0        | demand     |
| `countryd` (adjacent)          | system        | 0     | ~11 MB   | yes        |
| **Core stack total**           |               |       | **~114 MB** |         |

\* `geod` is an on-demand XPC service (`ServiceType: User`) but three instances stay resident while clients hold connections.

Disk: `~/Library/Caches/GeoServices` ≈ **55 MB** (tiles/manifests, not RSS).

## Launchd Labels (core stack)

| Label                         | Domain | Plist path                                                       | Type          |
|-------------------------------|--------|------------------------------------------------------------------|---------------|
| `com.apple.locationd`         | system | `/System/Library/LaunchDaemons/com.apple.locationd.plist`        | LaunchDaemon  |
| `com.apple.CoreLocationAgent` | gui    | `/System/Library/LaunchAgents/com.apple.CoreLocationAgent.plist` | LaunchAgent   |
| `com.apple.geodMachServiceBridge` | gui | `/System/Library/LaunchAgents/com.apple.geodMachServiceBridge.plist` | LaunchAgent |
| `com.apple.locationaccessstored`  | gui | `/System/Library/LaunchAgents/com.apple.locationaccessstored.plist`  | LaunchAgent |

`com.apple.geod` has **no launchd label**. It is an XPC bundle:

```text
/System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/XPCServices/com.apple.geod.xpc
Bundle ID: com.apple.geod
ServiceType: User
```

Instances appear under `user/<uid>/com.apple.geod` domains (e.g. `user/205`, `user/262`, `user/502`).

## locationd — Central Daemon

| Field    | Value                    |
|----------|--------------------------|
| Binary   | `/usr/libexec/locationd` |
| User     | `_locationd` (uid 205)   |
| Home     | `/var/db/locationd`      |
| KeepAlive| `SuccessfulExit => false`|
| Jetsam   | soft 40 MB active/inactive |

### MachServices (endpoints)

| Endpoint                               | Active | Role |
|----------------------------------------|--------|------|
| `com.apple.locationd.desktop.agent`    | yes    | Channel for `CoreLocationAgent` and desktop location plumbing |
| `com.apple.locationd.desktop.registration` | yes | Client registration for CoreLocation API |
| `com.apple.locationd.desktop.synchronous` | yes | Synchronous location queries; used by `geod`, `NotificationCenter` |
| `com.apple.locationd.desktop.spi`      | no     | SPI / privileged desktop interface (on demand) |
| `com.apple.locationd.routine`          | yes    | CoreRoutine / habit location feed (client `routined` now disabled) |
| `com.apple.locationd.simulation`       | yes    | Location simulation / testing |

### Event channels / LaunchEvents

| Channel / activity | Purpose |
|--------------------|---------|
| `com.apple.locationd-events` | Darwin notify bus; was used by `remindd` (now disabled) |
| `com.apple.xpc.activity` → `com.apple.locationd.MetricHeartbeat` | Maintenance metrics every ~4h |
| `com.apple.xpc.activity` → `com.apple.locationd.CLClientManager.usersrecencycheck` | Very long-interval client housekeeping |

### Key entitlements (selected)

`locationd` is deeply wired into system infrastructure:

```text
WiFi: scan, power, events, priority id "core_location", 80211 user client
Bluetooth: system access, advertisement buffers
timed: GPS / LocationServer / HarvestServer time sources
Motion/HID: privileged motion events, orientation, device motion
CoreRoutine: Visit, LocationOfInterest (routined disabled; capability remains)
Place inference, micro-location, emergency place inference
searchparty advertisement cache (Find My disabled; entitlements remain)
rapport, CompanionLink, systemstatus.publisher
countryd contribute, geoservices geoip
```

### Known live clients (procinfo / entitlements scan)

These running processes hold or may hold `locationd` Mach lookups:

```text
WiFiAgent          - effective_bundle; WiFi regulatory domain
airportd           - spectator, locationd-events, effective_bundle
timed              - time sync via location/GPS sources
bluetoothd         - locationd.activity, effective_bundle
nearbyd            - inertial odometry, spectator, activity
intelligentroutingd - milo_connection
milod              - place_inference, microlocation export
ospredictiond      - geod + locationd.synchronous + activity
NotificationCenter - usage_oracle, desktop.registration, desktop.synchronous
```

Disabling `locationd` would affect Wi-Fi region selection, automatic timezone, Bluetooth location features, and any app using CoreLocation API.

## CoreLocationAgent — Desktop Permission Agent

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/CoreServices/CoreLocationAgent.app/.../CoreLocationAgent` |
| Domain  | gui/502 |
| RSS     | ~46 MB (largest single process in this stack) |
| Spawn   | `immediate reason = ipc (mach)` — not RunAtLoad |
| Jetsam  | soft 50 MB |

### Endpoints

| Endpoint                      | Role |
|-------------------------------|------|
| `com.apple.CoreLocation.agent`| User-facing location permission / agent surface |

`EnablePressuredExit => true` — can exit under memory pressure, but respawns when something needs location UI.

**Coding impact if disabled:** apps or system components requesting location may fail silently or without permission dialogs. Unknown whether headless SSH coding workflow needs it at all — **candidate for isolated test**, not first move.

## geod — GeoServices XPC

| Field   | Value |
|---------|-------|
| Binary  | `.../com.apple.geod.xpc/Contents/MacOS/com.apple.geod` |
| Type    | XPC service, per-user instance |
| Jetsam  | soft 19 MB per instance |
| Network | `com.apple.security.network.client` — reaches Apple geo servers |
| Cache   | `~/Library/Caches/GeoServices`, `~/Library/Caches/MapTiles`, etc. |

### Endpoint (per instance)

| Endpoint         | Domain example |
|------------------|----------------|
| `com.apple.geod` | `user/502` port active |

### Observed instances

| PID domain  | UID | Owner              | Container path |
|-------------|-----|--------------------|----------------|
| user/205    | 205 | `_locationd`       | `/var/db/locationd/Library/Containers/com.apple.geod/Data` |
| user/262    | 262 | `_cmiodalassistants` | `/var/db/cmiodalassistants/Library/Containers/com.apple.geod/Data` |
| user/502    | 502 | `codexadmin`       | `~/Library/Containers/com.apple.geod/Data` |

### geod Mach lookups (entitlements)

```text
com.apple.locationd.desktop.synchronous
com.apple.timed.xpc
com.apple.Maps.mapspushd.geoservices
com.apple.CallHistorySyncHelper
com.apple.CrashReporterSupportHelper
```

`geod` is the **map tile / geocoding / GeoServices** layer. It is a client of `locationd`, not a parent. There is no simple `launchctl disable` label — instances are XPC-launched per user session.

## geodMachServiceBridge

| Field  | Value |
|--------|-------|
| Binary | `/System/Library/PrivateFrameworks/GeoServices.framework/geodMachServiceBridge` |
| RSS    | ~4.5 MB |
| RunAtLoad | false |

### Endpoint

| Endpoint                   | Role |
|----------------------------|------|
| `com.apple.geod.cachedelete` | CacheDelete integration for GeoServices caches |

Low-risk, tiny footprint. Disabling saves little RAM; mainly affects cache cleanup plumbing.

## locationaccessstored

| Field  | Value |
|--------|-------|
| Binary | `/usr/libexec/locationaccessstored` |
| State  | **not running** (demand) |

### Endpoint

| Endpoint                                  | Role |
|-------------------------------------------|------|
| `com.apple.locationaccessstored.registration` | Registration for stored location-access state |

### LaunchEvents

```text
com.apple.bg.system.task — repeating every 14400s (Utility)
com.apple.notifyd — com.apple.locationd.appreset
```

Wakes on location preference resets. Low idle cost.

## Adjacent Satellites (not core, but location-related)

These are **separate disable candidates** outside the core stack:

| Label / process   | State now   | RSS   | Notes |
|-------------------|-------------|-------|-------|
| `com.apple.countryd` | running  | ~11 MB | Region/country DB; `geod` reads `/var/db/com.apple.countryd/` |
| `com.apple.timed`    | running  | ~7 MB  | **KeepAlive** — uses locationd for time sources; do not disable |
| `com.apple.weatherd` | not running | 0  | Weather daemon; `predicted-locations` endpoint; on-demand |
| `com.apple.Maps.mapspushd` | not running | 0 | Maps push; `mapspushd.geoservices` endpoint |
| `com.apple.navd`     | not running | 0  | Navigation; KeepAlive when `~/Library/Caches/GeoServices/Navd/working` exists |

## Dependency Graph (simplified)

```text
[Apps / System UI]
        │
        ├─► CoreLocationAgent ──► locationd.desktop.agent
        │
        ├─► geod (per user) ──► locationd.desktop.synchronous
        │         │
        │         └─► network → Apple GeoServices / map tiles
        │
        └─► direct CoreLocation API ──► locationd.desktop.registration / synchronous

locationd ◄── WiFiAgent, airportd (regulatory domain)
locationd ◄── timed (timezone / GPS time)
locationd ◄── bluetoothd, nearbyd (proximity / motion fusion)
locationd ◄── milod, intelligentroutingd, ospredictiond (micro-location / prediction)

countryd ──► geod (region data)
```

## Disable / Rollback Matrix (research — not tested)

| Target | Method | Est. savings | Risk | Coding impact | Notes |
|--------|--------|--------------|------|---------------|-------|
| `locationd` | `launchctl disable system/...` | ~48 MB (hub+geod205) | **4** | Wi-Fi region, timezone, CoreLocation API | **Disabled on target** — see `location-services-off` |
| `CoreLocationAgent` | `launchctl disable gui/...` | ~46 MB | **3** | No location permission UI | Test candidate; may respawn via mach IPC |
| `geod` user/502 instance | no label; kill XPC or remove clients | ~17 MB | **2** | Maps/Weather geo, some NC features | Respawns while clients exist |
| `geod` user/205 / user/262 | same | ~19 MB each | **3** | locationd / camera assistant geo internals | Collateral risk |
| `geodMachServiceBridge` | `launchctl disable gui/...` | ~4.5 MB | **1** | Cache delete only | Marginal gain |
| `locationaccessstored` | `launchctl disable gui/...` | ~0 idle | **2** | Location permission persistence tasks | Low priority |
| `weatherd` | `launchctl disable gui/...` | 0 (idle) | **1** | Weather app / widgets | Safe if Weather unused |
| `mapspushd` | `launchctl disable gui/...` | 0 (idle) | **1** | Maps push notifications | Safe if Maps unused |
| `navd` | `launchctl disable gui/...` | 0 (idle) | **1–2** | Turn-by-turn / navigation cache | Check Navd cache path |
| `countryd` | `launchctl disable system/...` | ~11 MB | **2–3** | Region/country resolution for geo stack | May affect geod; test carefully |

## Recommended Experiment Order (future)

1. **Idle satellites:** `weatherd`, `mapspushd`, `navd` — low RSS now, easy labels, reversible.
2. **Tiny bridge:** `geodMachServiceBridge` — small win, low risk.
3. **CoreLocationAgent** — only with reboot + health checks; verify no unexpected GUI/TCC breakage.
4. **geod pressure test** — identify which clients keep the three instances alive before trying to limit them.
5. ~~**locationd**~~ — **done on target** 2026-06-29 (`location-services-off`).

## Disable (`location-services-off`)

**Prerequisite:** Find My, `nearbyd`, `countryd`, `milod`, Maps sync, location satellites (`CoreLocationAgent`, `weatherd`, `navd`, `geodMachServiceBridge`) already off.

```bash
sudo launchctl bootout system/com.apple.locationd 2>/dev/null || true
sudo launchctl disable system/com.apple.locationd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.locationd
sudo shutdown -r now
```

## Test Result — `location-services-off` (2026-06-29, target `codexadmin` uid 502)

Clean reboot after disabling **only** `system/com.apple.locationd`.

### Headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| `locationd` disabled, not running | **PASS** |
| `geod` instances gone post-reboot | **PASS** (collateral with hub off) |
| 60s no respawn | **PASS** |
| `en0` active, IP `192.168.1.175`, default route | **PASS** |
| `configd` / `mDNSResponder` / `bluetoothd` running | **PASS** |
| `softwareupdate --list` | **PASS** |
| Keychain | **PASS** |
| Safari + Terminal + Happ + Finder + Settings | **PASS** |
| Audio idle | **PASS** |
| Rollback | **not needed** |

**Savings:** ~48 MB (`locationd` ~29 MB + internal `geod` user/205 ~19 MB).

### Who tried `locationd` (failed lookup since boot)

| Requestor | Count |
|-----------|-------|
| `airportd` | 23 |
| `ControlCenter` | 4 |
| `networkserviceproxy` | 3 |
| `WallpaperSequoia` | 2 |
| `intelligentroutingd` | 1 |
| `PowerUIAgent` | 1 |

**Last 2m:** 0 new lookups — boot burst only, **no storm**.

### Logs

| Signal | Result |
|--------|--------|
| `locationd` process lines | **1** |
| `geod` errors | **3** |
| `tccd` storm | **no** |
| Wi-Fi functional despite `airportd` lookups | **PASS** (SSH/route/DNS/IP OK) |

### GUI / operator notes (user, 2026-06-29)

| Check | Result |
|-------|--------|
| Desktop / Wi‑Fi / apps | **PASS** — «впринципе норм» |
| Location Services pane | **degraded expected** (not fully re-tested) |
| Persistent log hammering | **mild concern** — not a storm, but not zero |

**Idle log check (~5 min post-reboot):** real `failed lookup → locationd` in last 60s = **0** (only our `log show` lines). Boot burst ~32 lookups from `airportd`/ControlCenter in first minute, then quiet. Background: `airportd` scan/XPC noise (~13 errors/60s), plus ecosystem failed lookups (Notes, akd, secd, Finder) from other disabled stacks — **not a respawn loop**.

**Operator verdict:** **keep disabled** on no-location coding target, but treat as **borderline / slightly questionable** for «hard optimization» profile:

- Small ongoing log chatter remains (airportd + cross-service XPC misses).
- Wi‑Fi/network/SSH OK so far; **something may still break** under aggressive tuning (regulatory domain, timezone, rare System Settings paths) — monitor if pushing further.
- Rollback `system/com.apple.locationd` is the recovery lever if Wi‑Fi region/timezone oddities appear.

## Test Result — research baseline (2026-06-20)

Read-only research. Post–Find My: `locationd` + satellites running; disabling Find My did not stop hub.

## Expected Breakage (if core components disabled)

### locationd

- Wrong or unstable Wi-Fi regulatory domain / channel selection
- Automatic timezone detection may stop
- CoreLocation API breaks for all apps
- Bluetooth/nearby location-assisted features degrade
- `timed` may lose GPS-based time sources

### CoreLocationAgent

- Location permission prompts may not appear
- Some apps may fail to register as location clients

### geod

- Maps geocoding, map tiles, GeoServices lookups fail
- Weather location features degrade
- GeoServices cache stops updating (disk may still remain)

## Geod Client Tracing (2026-06-20, after CoreLocationAgent disable)

Three `geod` XPC instances remain resident at idle. There is **no launchd label** to disable; instances live under `user/<uid>/com.apple.geod`.

| Instance | UID | Domain   | RSS   | Likely launcher / holder |
|----------|-----|----------|-------|---------------------------|
| geod     | 205 | user/205 | ~19 MB | **`locationd` itself** — internal GeoServices inside `_locationd` container |
| geod     | 262 | user/262 | ~19 MB | **`_cmiodalassistants`** — camera / Continuity Capture assistant stack |
| geod     | 502 | user/502 | ~17 MB | **`ospredictiond`** — direct `com.apple.geod` mach lookup observed |

Additional processes using **locationd** APIs (may indirectly keep geo plumbing warm):

```text
NotificationCenter  - locationd.desktop.synchronous, desktop.registration
ospredictiond       - com.apple.geod + locationd.synchronous
WiFiAgent, airportd - effective_bundle / spectator (locationd, not geod directly)
milod, nearbyd, intelligentroutingd - locationd micro-location / activity APIs
```

**Conclusion:** user/502 `geod` may be droppable only if `ospredictiond` (or similar clients) are addressed. user/205 `geod` is effectively part of `locationd` internals. user/262 `geod` ties to camera/continuity infrastructure — high collateral risk.

Disabling `CoreLocationAgent` did **not** remove any `geod` instance.

## Satellite Experiments Completed (same day)

| Group | Labels | Result |
|-------|--------|--------|
| Idle satellites | `weatherd`, `mapspushd`, `navd` | Disabled, validated — see `services/com.apple.weatherd/service.md` |
| Cache bridge | `geodMachServiceBridge` | Disabled, validated — see `services/com.apple.geodMachServiceBridge/service.md` |
| Desktop agent | `CoreLocationAgent` | Disabled, validated — see `services/com.apple.CoreLocationAgent/service.md` |

Satellites disabled before core hub kill (2026-06-29). Core hub now off on target.

## Notes / Unresolved

- `ospredictiond` was disabled 2026-06-20 — see `services/com.apple.ospredictiond/service.md`. user/502 `geod` **still remains** (~17 MB); other clients (e.g. `NotificationCenter`) still hold it.
- `CoreLocationAgent` at **46 MB** was successfully removed; largest location-stack win so far without touching `locationd`.
- `locationd` still exposes `searchpartyd` and `CoreRoutine` entitlements after those clients were disabled — harmless leftover capability.
- `countryd` is adjacent, not inside the four core plists, but couples to `geod` region resolution.
- No safe bulk-disable path exists for `geod`; XPC architecture requires client-first approach.

## Related Cards

- `services/com.apple.findmy/service.md` — Find My layer disabled; proved `locationd` independence
- `services/com.apple.routined/service.md` — was a `locationd.routine` client; now disabled