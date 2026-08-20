# Micro-location / places of interest — `milod` (milod-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `milod` only                                                  |
| Category      | Micro-location / places of interest disabled                    |
| Risk Level    | **1–2** — consumer geo daemon; headless clean on this target  |
| Profile       | **keep disabled on no-micro-location coding target**            |

## What It Does (за что отвечает)

Per-user **MicroLocation** daemon (`man milod`: *provides MicroLocation services*):

| Responsibility | Detail |
|----------------|--------|
| Micro-location | Fine-grained location context beyond coarse GPS |
| Places of interest | Routine / frequent-place inference (`RTLocationsOfInterest*` notifications) |
| XPC API | `com.apple.milod.xpc.service` |
| WiFi analyzer | Daily background `milod.wifiAnalyzer` (power + inactivity gated) |
| Analytics / backup | `milod.analytics`, `milod.exportiCloudBackup` maintenance tasks |
| Upstream to | `locationd` (place inference / microlocation export), `intelligentroutingd` (`milo_connection`) |

**Not touched:** `locationd`, `geod`, `nearbyd`, `countryd`, `eligibilityd`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.milod` | gui | `milod` | `/System/Library/LaunchAgents/com.apple.milod.plist` |

**Binary:** `/usr/libexec/milod` (`com.apple.MicroLocation`)

**Launch:** no `RunAtLoad`; starts on Mach IPC.

## Who Was Calling It (before disable)

| Source | Finding |
|--------|---------|
| Unified logs (30m before) | **0** milod/MicroLocation lines — idle in logs |
| Boot trigger | Launched at login via Mach IPC (`immediate reason = ipc (mach)`) |
| Active XPC clients at snapshot | None visible in logs during observation window |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `milod` | ~18 MB |

## Clean Reboot Protocol (no app/window restore)

To avoid restored apps skewing RAM baseline:

```bash
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
defaults write -g NSQuitAlwaysKeepsWindows -bool false
# Saved Application State was already empty on target
sudo shutdown -r now
```

**Post-reboot confirmation:** `TALLogoutSavesState=0`, `LoginwindowLaunchesRelaunchApps=0`, Saved Application State dirs **0**.

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.milod" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.milod"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.milod"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **milod-off**

**Context:** `countryd`, `eligibilityd` already disabled from prior tests.

**Before (clean session baseline):** processes **297**, total RSS **5436 MB**, `milod` running (~18 MB).

1. Configure no app/window restore; disable `gui/502/com.apple.milod` — gone immediately.
2. **Clean reboot** — SSH back ~25 s; login restore flags confirmed off; no Saved Application State.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `milod`: **not running**; disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 milod/MicroLocation lines; 0 error/fail/retry
   - **Neighbors:**

| Neighbor | Status | Log noise |
|----------|--------|-----------|
| `locationd` | running (~29 MB) | **none** |
| `geod` | running (×2) | **none** |
| `nearbyd` | running (~17 MB) | **none** |
| `countryd` | disabled (prior) | **none** |
| `eligibilityd` | disabled (prior) | **none** |

4. **After metrics:** processes **306**, total RSS **5576 MB** (~18 MB from milod removed; slight boot variance up)

**Verdict: keep disabled on coding experimental target.**

## Exact Breakage Notes (expected, GUI not tested)

| Area | Impact |
|------|--------|
| Micro-location | No MicroLocation XPC service |
| Places of interest | Routine / frequent-place inference stops updating |
| Location-based suggestions | Consumer geo-context hints stale |
| Maps/Calendar/Reminders/Siri location hints | Possible loss of microlocation-backed suggestions |
| `locationd` coupling | May lose microlocation export input; **no headless retry storm observed** |

**Not broken (verified headless):** SSH; `locationd`/`geod`/`nearbyd` stayed up quietly.

## Notes

- Consumer geo tail in same family as `nearbyd` (still running).
- Re-enable if using Maps routine places, microlocation-backed suggestions, or debugging MicroLocation on this Mac.