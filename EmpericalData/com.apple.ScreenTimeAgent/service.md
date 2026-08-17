# Screen Time / Live Activities / Usage Tracking / Social Layer

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Live Activities, Screen Time, app usage tracking, Social Layer  |
| Category      | `ui_required` / consumer Apple ecosystem                       |
| Risk Level    | 1 — not needed for coding workflow; not boot-critical          |

## What It Does

Four related per-user LaunchAgents for consumer engagement features:

| Daemon | Role |
|--------|------|
| **liveactivitiesd** | Live Activities — dynamic lock screen / Dynamic Island widgets (sports, delivery, timers) |
| **ScreenTimeAgent** | Screen Time — app limits, Downtime, usage reports, family controls |
| **UsageTrackingAgent** | Collects app/system usage data for Screen Time statistics |
| **sociallayerd** | Social Layer — Shared with You, share-sheet contact suggestions, collaboration hints |

None of this is required for SSH, compilers, Git, or a headless/coding-focused Mac.

## Observed Cost (before disable)

| Process              | RSS     |
|----------------------|---------|
| `liveactivitiesd`    | ~18.6 MB |
| `ScreenTimeAgent`    | ~18.4 MB |
| `UsageTrackingAgent` | ~16.3 MB |
| `sociallayerd`       | ~16.1 MB |
| **Total**            | **~69 MB** |

## Launchd Labels

| Label                         | Plist                                                            | Domain |
|-------------------------------|------------------------------------------------------------------|--------|
| `com.apple.liveactivitiesd`   | `/System/Library/LaunchAgents/com.apple.liveactivitiesd.plist`   | gui    |
| `com.apple.ScreenTimeAgent`   | `/System/Library/LaunchAgents/com.apple.ScreenTimeAgent.plist`   | gui    |
| `com.apple.UsageTrackingAgent`| `/System/Library/LaunchAgents/com.apple.UsageTrackingAgent.plist`| gui    |
| `com.apple.sociallayerd`      | `/System/Library/LaunchAgents/com.apple.sociallayerd.plist`      | gui    |

Related but **not** disabled in this test: `com.apple.ScreenTimeSettingsAgent` (settings UI helper; was not running).

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.liveactivitiesd
  com.apple.ScreenTimeAgent
  com.apple.UsageTrackingAgent
  com.apple.sociallayerd
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in \
  com.apple.liveactivitiesd \
  com.apple.ScreenTimeAgent \
  com.apple.UsageTrackingAgent \
  com.apple.sociallayerd; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all 4 processes running (~69 MB RSS total).
2. Bootout all 4 gui labels — all processes disappeared immediately.
3. No errors in logs after bootout.
4. 30-second delayed check — none returned.
5. Disabled all 4 labels — confirmed in `launchctl print-disabled`.
6. Rebooted target; SSH back in ~19 seconds.
7. Post-reboot health: SSH, login, gateway, memory pressure OK.
8. No liveactivities/ScreenTime/UsageTracking/sociallayer processes after reboot.
9. `ScreenTimeSettingsAgent` not running (unchanged).
10. No related error log entries during boot.
11. Process count: **334** (down from 338).

**Verdict: safe to disable on coding experimental target.** ~69 MB saved.

## Expected Breakage

- Live Activities widgets stop updating.
- Screen Time limits, Downtime, and usage reports stop working.
- App usage statistics no longer collected.
- Shared with You / social share suggestions may degrade.

No observed impact on SSH, networking, or core desktop shell.

## Notes

- Grouped as one bundle — same risk profile and no coding dependency.
- `com.apple.GamePolicyAgent` / `gamepolicyd` disabled separately (game policy, adjacent to parental controls).
- Re-enable before using Screen Time parental controls or Live Activities on this Mac.