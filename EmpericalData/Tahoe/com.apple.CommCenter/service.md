# CommCenter — Cellular / CoreTelephony

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `CommCenter` — CoreTelephony / cellular stack on macOS           |
| Category      | `networking` / consumer telephony                                |
| Risk Level    | 1–2 — safe on Macs without cellular; not needed for coding       |

## What It Does

LaunchAgent for Apple's **CommCenter** / CoreTelephony framework. On MacBook Air without cellular modem it provides telephony-related plumbing (historically for iMac-with-cellular models and shared iOS frameworks).

Plist: `/System/Library/LaunchAgents/com.apple.CommCenter-osx.plist`

`LimitLoadFromHardware` restricts loading on many Intel iMac models; on Apple Silicon MacBook Air it may be demand-started but is unused without cellular hardware.

## Observed Cost (before disable)

| Process      | State at capture | RSS |
|--------------|------------------|-----|
| `CommCenter` | **not running** at disable time | 0 |

Previously observed ~32 MB RSS when running on same target earlier in session.

## Launchd Labels

| Label                | Plist                                                         | Domain |
|----------------------|---------------------------------------------------------------|--------|
| `com.apple.CommCenter` | `/System/Library/LaunchAgents/com.apple.CommCenter-osx.plist` | gui    |

### LaunchEvents

```text
com.apple.coretelephony.kvstorechange (notifyd)
```

KeepAlive via PathState `/tmp/CommCenter.KeepAlive.Enabled` when active.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.CommCenter" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.CommCenter"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.CommCenter"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `CommCenter` label present but process **not running** (idle).
2. Bootout — no process to remove.
3. 30-second delayed check — still not running.
4. Disabled label — confirmed in `launchctl print-disabled`.
5. Rebooted with `donotdisturbd` disable in same session; SSH back ~18 seconds.
6. Post-reboot: no `CommCenter` process; no related boot errors.
7. Health: gateway, Wi-Fi interface, memory pressure OK.
8. Process count: 333.

**Verdict: safe to disable on MacBook Air M4 coding target without cellular.**

## Expected Breakage

- CoreTelephony / cellular-related features if hardware or eSIM were present.
- Any app relying on CommCenter XPC on this Mac.

No observed impact on Wi-Fi, SSH, or Ethernet networking.

## Notes

- Disabled together with `donotdisturbd` in one reboot for efficiency; separate service cards and commits.
- Re-enable if using cellular-capable Mac or telephony-dependent software.