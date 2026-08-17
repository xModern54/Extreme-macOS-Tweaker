# Do Not Disturb / Focus Server

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `donotdisturbd` — Focus modes and Do Not Disturb server        |
| Category      | `ui_required` / consumer notifications                         |
| Risk Level    | 1 — not needed for coding workflow                               |

## What It Does

Per-user LaunchAgent for macOS Focus / Do Not Disturb server-side logic: scheduling focus modes, notification filtering, DND state sync.

Binary: `/System/Library/PrivateFrameworks/DoNotDisturbServer.framework/Support/donotdisturbd`

Not required for SSH, compilers, Git, or headless coding.

## Observed Cost (before disable)

| Process         | Domain | RSS     |
|-----------------|--------|---------|
| `donotdisturbd` | gui    | ~31 MB  |

## Launchd Labels

| Label                   | Plist                                                            | Domain |
|-------------------------|------------------------------------------------------------------|--------|
| `com.apple.donotdisturbd` | `/System/Library/LaunchAgents/com.apple.donotdisturbd.plist`   | gui    |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.donotdisturbd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.donotdisturbd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.donotdisturbd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `donotdisturbd` running ~31 MB RSS.
2. Bootout — process disappeared immediately; no log errors.
3. 30-second delayed check — did not return.
4. Disabled label — confirmed in `launchctl print-disabled`.
5. Rebooted with `CommCenter` disable in same session; SSH OK.
6. Post-reboot: no `donotdisturbd` process; no related boot errors.
7. Health: gateway, memory pressure OK.

**Verdict: safe to disable on coding experimental target.**

## Expected Breakage

- Focus modes and Do Not Disturb scheduling/filtering on this Mac.
- System Focus state integration may degrade.

No impact on SSH, Wi-Fi, or boot stability observed.

## Notes

- Disabled in same reboot batch as `com.apple.CommCenter`; see that card for shared reboot metadata.