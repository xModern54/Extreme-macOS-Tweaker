# Nearby interaction / proximity / UWB — `nearbyd` (nearbyd-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `nearbyd` only                                                |
| Category      | Nearby interaction / proximity / UWB disabled                   |
| Risk Level    | **1–2** — proximity daemon; headless clean; BT stack untouched |
| Profile       | **keep disabled on no-nearby coding target**                  |

**GUI-confirmed:** Bluetooth pairing still works after `nearbyd-off` (user paired keypad successfully).

## What It Does (за что отвечает)

**System** proximity daemon (`man nearbyd`: *powers spatial interaction experiences between devices using ultra wideband and other wireless technologies*). User: `_nearbyd` — *Proximity and Ranging Daemon*.

| Responsibility | Detail |
|----------------|--------|
| Nearby Interaction | UWB/ranging via `com.apple.nearbyd.xpc.nearbyinteraction` (+ observer) |
| Bluetooth discovery input | Listens `com.apple.bluetooth.discovery` (client, not BT stack) |
| Location coupling | Subscribes `com.apple.locationd-events` |
| Inertial odometry | Motion/proximity fusion for nearby features |

**Not touched:** `locationd`, `bluetoothd`, `bluetoothuserd`, `airportd`, `wifip2pd`, `sharingd`, `rapportd`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.nearbyd` | system | `nearbyd` | `/System/Library/LaunchDaemons/com.apple.nearbyd.plist` |

**Binary:** `/usr/libexec/nearbyd`

## Who Was Calling It (before disable)

| Source | Finding |
|--------|---------|
| Unified logs (30m before) | **0** nearbyd / nearbyinteraction lines — idle |
| Active XPC clients | None visible in logs during observation |
| Context | `sharingd` and `rapportd` already disabled; `nearbyd` still ran independently |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `nearbyd` | ~17 MB |

## Clean Reboot (no app restore)

```bash
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
defaults write -g NSQuitAlwaysKeepsWindows -bool false
sudo shutdown -r now
```

## Disable (system only)

```bash
sudo launchctl bootout system/com.apple.nearbyd 2>/dev/null || true
sudo launchctl disable system/com.apple.nearbyd
```

Note: process may remain until reboot on this target; disable flag applies after reboot.

## Rollback

```bash
sudo launchctl enable system/com.apple.nearbyd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **nearbyd-off**

**Context:** `sharingd`, `rapportd` already disabled.

**Before:** processes **269**, total RSS **4375 MB**, `nearbyd` running (~17 MB).

1. Clean-reboot prefs + bootout/disable `system/com.apple.nearbyd` — disable flag set; process lingered until reboot.
2. Reboot — SSH back ~19 s; `TALLogoutSavesState=0`, `LoginwindowLaunchesRelaunchApps=0`.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `nearbyd`: **not running**; system disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 nearbyd/proximity/ranging/nearbyinteraction lines; 0 error/fail/retry
   - **Protected neighbors — still running, quiet:**

| Neighbor | Status | Log noise |
|----------|--------|-----------|
| `locationd` | running (~29 MB) | **none** |
| `bluetoothd` | running (~36 MB) | **none** |
| `bluetoothuserd` | running (~17 MB) | **none** |
| `airportd` | running (~38 MB) | **none** |
| `wifip2pd` | running (~21 MB) | **none** |
| `sharingd` | disabled (prior) | n/a |
| `rapportd` | disabled (prior) | n/a |

4. **After metrics:** processes **272**, total RSS **4249 MB** (~17 MB from nearbyd removed)
5. **Post-test (GUI, user-confirmed):** paired **Bluetooth keypad** successfully after `nearbyd-off` — **BT stack not broken** (pairing/connect works).

**Verdict: keep disabled on coding experimental target.**

## Exact Breakage Notes (headless + GUI-confirmed BT OK)

| Area | Impact |
|------|--------|
| Nearby Interaction / UWB ranging | XPC endpoints gone |
| Proximity discovery | No nearbyd BT-discovery fusion |
| Device-nearby Apple features | Handoff/AirDrop proximity layer further reduced (sharing already off) |
| Find My / Precision Finding style proximity | Expected unavailable/stale |
| `locationd` nearby input | May lose nearbyd-side proximity feed; **no headless retry storm observed** |

**Does NOT break (verified):** Bluetooth stack — **GUI-confirmed** keypad pairing works; headless: `bluetoothd`, `bluetoothuserd` running quiet. Also OK: Wi-Fi (`airportd`, `wifip2pd`); SSH; `locationd` uptime.

## Neighbors After Disable

| Component | Noise after disable + reboot |
|-----------|------------------------------|
| `bluetoothd` / `bluetoothuserd` | running, **quiet** — BT not killed |
| `locationd` | running, **quiet** |
| `airportd` / `wifip2pd` | running, **quiet** |
| `sharingd` / `rapportd` | remain disabled, unchanged |
| `nearbyd` | **gone**, no respawn |

## Notes

- Distinct from `bluetoothd` — disabling nearbyd does **not** disable Bluetooth radio/pairing.
- Complements prior `sharingd`/`rapportd` disables for continuity stack teardown.
- Re-enable only if using UWB/Nearby Interaction or proximity-heavy Apple features on this Mac.