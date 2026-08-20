# Camera / CMIO / capture stack — `registerassistantservice` (camera-stack-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | CMIO / camera capture stack (see label list below)            |
| Category      | Camera / CMIO / capture disabled                              |
| Risk Level    | **3** — breaks all camera/capture paths; OK if camera unused  |
| Profile       | **keep disabled on no-camera coding target**                  |

User does not use camera at all on this Mac. **GUI-confirmed:** after disable, camera **fully non-functional for any client**.

## What It Does (за что отвечает)

**`com.apple.cmio.registerassistantservice`** is the CoreMediaIO DAL orchestrator (`man`: registration of A/V capture plug-ins / system extensions). It bootstraps the **`_cmiodalassistants` (uid 262)** domain and related capture daemons.

### Label group disabled in this test

| Label | Domain | Role |
|-------|--------|------|
| `com.apple.cmio.registerassistantservice` | system | CMIO DAL registration / extension orchestrator |
| `com.apple.cameracaptured` | system | Camera capture daemon |
| `com.apple.appleh16camerad` | system | Apple Silicon built-in camera driver |
| `com.apple.appleh13camerad` | system | Intel/older camera driver (idle on M4) |
| `com.apple.cmio.uvcassistantextension` | system | USB UVC webcam assistant |
| `com.apple.cmio.videodriverkithostextension` | system | Video driver kit host |
| `com.apple.cmio.VDCAssistant` | system | Virtual/device camera assistant |
| `com.apple.cmio.iOSScreenCaptureAssistant` | system | iOS screen capture assistant |
| `com.apple.ptpcamerad` | gui | PTP/USB camera daemon |
| `com.apple.cmio.ContinuityCaptureAgent` | gui | Continuity Camera (was already disabled) |
| `com.apple.cmio.LaunchCMIOUserExtensionsAgent` | gui | CMIO user extensions launcher |

### `_cmiodalassistants` stack (collapsed when orchestrator disabled)

Previously ~109 MB including: `cameracaptured`, `appleh16camerad`, `UVCAssistant`, `videodriverkithostextension`, **`geod` user/262**, trustd/secinitd helpers.

**Not touched:** `locationd`, `geod` user/205 (`_locationd` internal).

## Observed Cost (before disable)

| Scope | RSS |
|-------|-----|
| Camera/CMIO processes (incl. uid 262 + registerassistant + gui tails) | **~149 MB** |
| `registerassistantservice` alone | ~27 MB |
| uid 262 stack | ~109 MB |
| `geod` user/262 (collateral in camera stack) | ~18 MB |

## Disable

```bash
uid=$(id -u)
system_labels=(
  com.apple.cmio.registerassistantservice
  com.apple.cameracaptured
  com.apple.appleh16camerad
  com.apple.appleh13camerad
  com.apple.cmio.uvcassistantextension
  com.apple.cmio.videodriverkithostextension
  com.apple.cmio.VDCAssistant
  com.apple.cmio.iOSScreenCaptureAssistant
)
gui_labels=(
  com.apple.ptpcamerad
  com.apple.cmio.ContinuityCaptureAgent
  com.apple.cmio.LaunchCMIOUserExtensionsAgent
)
for label in "${system_labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
for label in "${gui_labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Clean Reboot (no app restore)

```bash
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
defaults write -g NSQuitAlwaysKeepsWindows -bool false
sudo shutdown -r now
```

## Rollback

```bash
uid=$(id -u)
# enable all labels above (swap disable → enable), then:
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **camera-stack-off**

**Before:** processes **301**, total RSS **5468 MB**, camera-related **~149 MB** (13 procs incl. uid 262 stack + `geod` user/262).

1. Disable full label group + clean-reboot prefs.
2. Reboot — SSH back ~21 s; `TALLogoutSavesState=0`, `LoginwindowLaunchesRelaunchApps=0`.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - **Gone:** `registerassistantservice`, `cameracaptured`, `appleh16camerad`, UVC/videodriverkit stack, entire **`_cmiodalassistants` uid 262 domain**, `ptpcamerad`
   - **`geod` user/262:** **gone** (collateral win ~18 MB)
   - **`geod` user/205:** still running (~19 MB, `locationd` internal)
   - **`locationd`:** running (~29 MB), **no cmio/camera error logs**
   - **Delayed 25 s:** no camera stack respawn
   - **Log storm:** 0 cmio/cameracapture/registerassistant errors
4. **Residual tail:** `mscamerad-xpc` (~6 MB) — ImageCaptureCore on-demand XPC, **no launchd label**; idle, no log noise
5. **After metrics:** processes **304**, total RSS **5819 MB**, camera-labeled RSS **~5.8 MB** (mscamerad only)

6. **Post-reboot (GUI, user-confirmed):** camera **fully dead for any client** — user opened Camera.app and other camera clients; **no working capture path** (built-in, USB, Continuity, third-party apps all broken). Intended outcome for no-camera profile.

**Verdict: keep disabled on no-camera coding target.**

## Exact Breakage Notes (GUI-confirmed)

**Camera fully stops working for any client** — not partial/degraded; capture stack is dead end-to-end.

| Broken | Detail |
|--------|--------|
| **All camera clients** | **Confirmed dead** — Camera.app, AVFoundation apps, any app requesting camera |
| Built-in FaceTime/Mac camera | `appleh16camerad`, `cameracaptured` down |
| USB / UVC webcams | `uvcassistantextension`, `ptpcamerad` down |
| Continuity Camera (iPhone webcam) | `ContinuityCaptureAgent` + CMIO orchestrator down |
| CMIO virtual cameras / extensions | `registerassistantservice` down |
| Zoom / Meet / Photo Booth / etc. | Camera input unavailable |

**Collateral (positive):** `geod` user/262 removed without separate `geod` surgery.

**Not broken (verified headless):** SSH; `locationd`; `geod` user/205.

## Neighbors After Disable

| Neighbor | Result |
|----------|--------|
| `locationd` | running, quiet |
| `geod` user/205 | running, quiet |
| `geod` user/262 | **gone** |
| `nearbyd` | unchanged (not part of this group) |
| `mscamerad-xpc` | ~6 MB idle tail, no launchd disable path found |

## Notes

- Largest single RAM win so far in geo/camera adjacency (~140+ MB camera stack removed).
- `ContinuityCaptureAgent` was already disabled before this wave.
- Re-enable entire label group before any camera/Continuity/AV capture use.