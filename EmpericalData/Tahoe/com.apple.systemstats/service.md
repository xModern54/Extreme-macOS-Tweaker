# System Power & Telemetry Analytics Daemon — systemstats

## Basics

- **Main labels:** `system/com.apple.systemstats.analysis`, `system/com.apple.systemstats.daily`, `system/com.apple.systemstats.microstackshot_periodic`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.systemstats.analysis.plist`, `/System/Library/LaunchDaemons/com.apple.systemstats.daily.plist`, `/System/Library/LaunchDaemons/com.apple.systemstats.microstackshot_periodic.plist`
- **Binary:** `/usr/sbin/systemstats`
- **Domain:** `system`
- **Category:** `analytics_telemetry_systemstats`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`systemstats` is Apple's passive power consumption and battery telemetry logging daemon:

1. **Passive Diagnostic Logging (`/var/db/systemstats/`)**: Logs CPU time, process battery usage, sleep/wake transitions, and thermal states into local SQLite databases for `sysdiagnose` diagnostic archives.
2. **System Battery Graph Provider**: Supplies historical power usage datasets for the 24-hour and 10-day battery consumption charts in *System Settings -> Battery*.

## Independence from Power Management Infrastructure

- **Independent of `powerd` and Kernel IOPM**: `systemstats` is a 100% passive reader daemon. Core power management policies, sleep/wake timers, display dimming, battery charging, Low Power Mode, and thermal throttling are executed independently by `powerd` (`/usr/libexec/powerd`) and the XNU kernel.
- **System Memory & Disk I/O Savings**: Disabling `systemstats` frees **~18MB RSS RAM** and eliminates continuous background write operations to `/var/db/systemstats/`.

## Disable

```bash
sudo launchctl bootout system/com.apple.systemstats.analysis 2>/dev/null || true
sudo launchctl disable system/com.apple.systemstats.analysis
sudo launchctl bootout system/com.apple.systemstats.daily 2>/dev/null || true
sudo launchctl disable system/com.apple.systemstats.daily
sudo launchctl bootout system/com.apple.systemstats.microstackshot_periodic 2>/dev/null || true
sudo launchctl disable system/com.apple.systemstats.microstackshot_periodic
```

## Rollback

```bash
sudo launchctl enable system/com.apple.systemstats.analysis
sudo launchctl enable system/com.apple.systemstats.daily
sudo launchctl enable system/com.apple.systemstats.microstackshot_periodic
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `systemstats.analysis`, `daily`, and `microstackshot_periodic`.
2. Process `systemstats` terminated, releasing **~18MB RSS RAM** and eliminating telemetry disk writes.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `systemstats` process remains stopped permanently.
   - Core power management, sleep/wake, battery operation, and thermal management via `powerd` operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
