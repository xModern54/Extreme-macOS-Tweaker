# Duet Activity Scheduler / dasd

## Basics

- **Main label:** `com.apple.dasd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.dasd-OSX.plist`
- **Binary:** `/usr/libexec/dasd`
- **Domain:** `system`
- **Category:** `background_scheduling_telemetry`
- **Risk:** `1`
- **Verdict:** `disable for coding / aggressive profile`

## What It Does

`dasd` (Duet Activity Scheduler Daemon) is the background heuristic task scheduler of macOS. It evaluates power, thermal, battery, and predictive user behavior (`CoreDuetContext`) to decide when to run deferred background tasks (Spotlight re-indexing, Photos media analysis, CoreML model downloads, software update checks, system telemetry, and Time Machine background snapshots).

### Strategic Optimization Note

When doing a total/aggressive system optimization — where the user has already disabled Apple Intelligence / Generative Experiences, Siri, photos analysis, and proactive context learning — `dasd` becomes an empty shell that loops over non-existent XPC services. In this state, `dasd` should be disabled completely ("выпилить с концами") to eliminate the ~7,600 errors/hour log storm and prevent unneeded background heuristic wakeups.

When CoreDuet / Proactive services (`routined`, `biomed`) are disabled, `dasd` enters a tight XPC retry loop attempting to fetch context values, generating ~7,600 error log lines per hour (86% of all system log errors).

## Known Launchd Labels

```text
system/com.apple.dasd
```

## Disable

```bash
sudo launchctl bootout system/com.apple.dasd
sudo launchctl disable system/com.apple.dasd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.dasd
sudo shutdown -r now
```

## Test Result

Validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `sudo launchctl bootout system/com.apple.dasd` and `sudo launchctl disable system/com.apple.dasd` applied.
2. Immediate check confirmed process `dasd` terminated and `com.apple.dasd` reported `disabled` in `system`.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 14 seconds.
5. Post-reboot health check (`./scripts/health-check.sh --phase post-reboot`) passed cleanly.
6. Delayed log analysis (30s post-boot):
   - `dasd` log errors dropped from **7,673 errors/hour** down to **0** active process errors.
   - Steady-state log errors across the entire system dropped to ~50 lines/10s (mostly active SSH session PAM logs).
   - System stability, network, SSH, terminal execution, memory pressure (95% free), and GUI console login operate normally.
