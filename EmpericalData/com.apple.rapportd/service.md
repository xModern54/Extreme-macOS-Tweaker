# Continuity / AirPlay / Handoff Stack

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `rapportd` + AirPlay UI/XPC + `replicatord` + Continuity Camera |
| Category      | `networking` / consumer continuity                               |
| Risk Level    | 2 — disables Handoff/AirPlay/Continuity Camera; BT audio kept   |

## What It Does

Apple **Continuity** and **AirPlay receiver** plumbing for nearby devices, screen/audio casting, and iPhone-as-webcam. Separate from core Bluetooth stack.

| Label | Process | Role |
|-------|---------|------|
| `com.apple.rapportd` | `rapportd` | Handoff / Continuity pairing / nearby IDS |
| `com.apple.AirPlayUIAgent` | `AirPlayUIAgent` | AirPlay receiver UI and session prompts |
| `com.apple.AirPlayXPCHelper` | `AirPlayXPCHelper` | System AirPlay XPC helper (system) |
| `com.apple.replicatord` | `replicatord` | Continuity state replication (chrono/app state) |
| `com.apple.cmio.ContinuityCaptureAgent` | `ContinuityCaptureAgent` | Continuity Camera (iPhone as webcam) |

**Kept enabled (per test plan):**

| Label | Process | Role |
|-------|---------|------|
| `com.apple.BTServer.cloudpairing` | `audioaccessoryd` | Bluetooth audio accessories / cloud pairing |

Not disabled: `bluetoothd`, `coreaudiod`.

## Observed Cost (before disable)

| Process | Domain | RSS |
|---------|--------|-----|
| `rapportd` | gui | ~30 MB |
| `AirPlayUIAgent` | gui | ~22 MB |
| `replicatord` | gui | ~22 MB |
| `ContinuityCaptureAgent` | gui | ~13 MB |
| `AirPlayXPCHelper` | system | ~12 MB |
| **Total** | | **~99 MB** |

## Launchd Labels

| Label | Plist area | Domain |
|-------|------------|--------|
| `com.apple.rapportd` | LaunchAgents `com.apple.rapportd-user.plist` | gui |
| `com.apple.AirPlayUIAgent` | LaunchAgents | gui |
| `com.apple.replicatord` | LaunchAgents | gui |
| `com.apple.cmio.ContinuityCaptureAgent` | LaunchAgents | gui |
| `com.apple.AirPlayXPCHelper` | LaunchDaemons | system |

## Disable

```bash
uid=$(id -u)
labels_gui=(
  com.apple.rapportd
  com.apple.AirPlayUIAgent
  com.apple.replicatord
  com.apple.cmio.ContinuityCaptureAgent
)
for label in "${labels_gui[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
sudo launchctl bootout system/com.apple.AirPlayXPCHelper 2>/dev/null || true
sudo launchctl disable system/com.apple.AirPlayXPCHelper
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.rapportd com.apple.AirPlayUIAgent com.apple.replicatord com.apple.cmio.ContinuityCaptureAgent; do
  launchctl enable "gui/$uid/$label"
done
sudo launchctl enable system/com.apple.AirPlayXPCHelper
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all five targets running (~99 MB RSS); `audioaccessoryd` (`BTServer.cloudpairing`) running ~32 MB.
2. Bootout/disable — target processes gone; `audioaccessoryd` remained.
3. 30-second delayed check — targets did not return.
4. Reboot — SSH back ~22 seconds.
5. Post-reboot: no `rapportd`, AirPlay, `replicatord`, or ContinuityCapture processes; disable flags intact.
6. **SSH:** OK (gateway `192.168.1.1` via `en0`).
7. **Audio:** `coreaudiod` running (~88 MB); `afplay` system sound succeeded.
8. **Bluetooth:** `bluetoothd` running; `system_profiler` reports **State: On**; `audioaccessoryd` still running.
9. **Log storm:** 0 boot-time log lines matching rapport/AirPlay/replicator; no error/retry loops in 5m window.
10. 45-second delayed check — targets still absent.
11. Process count: ~321.

**Verdict: safe to disable on coding experimental target when Handoff/AirPlay/Continuity Camera not needed.**

## Expected Breakage

- Handoff / Universal Clipboard / nearby Continuity features.
- AirPlay receiver (Mac as AirPlay speaker/display target).
- Continuity Camera (iPhone as Mac webcam).
- Continuity state replication via `replicatord`.

**Not broken (verified):** SSH, Wi-Fi, Bluetooth power/state, `audioaccessoryd`, core audio (`coreaudiod`).

## Notes

- `com.apple.sharingd` was already disabled earlier — overlapping AirDrop/Handoff surface further reduced.
- Do not confuse with `fairplayd` (FairPlay DRM) — unrelated, still runs.
- Re-enable if using AirPlay to this Mac or Continuity Camera in calls.