# Legacy Apple System Log (ASL) File Rotation Daemon — aslmanager

## Basics

- **Main label:** `system/com.apple.aslmanager`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.aslmanager.plist`
- **Binary:** `/usr/libexec/aslmanager`
- **Domain:** `system`
- **Category:** `system_logging_asl`
- **Risk:** `1` (for standard coding profiles)
- **Verdict:** `disable for coding profile`

## What It Does

`aslmanager` (Apple System Log Manager Daemon) is Apple's legacy ASL log file rotation and cleanup daemon (`syslogd` / `/var/log/asl/`):

1. **Legacy ASL Text Log Compressor**: Triggers when legacy text log files reach `file_max = 5M` or folder size exceeds `all_max = 50M`, compressing `.asl` logs into `.gz` archives.
2. **Log File Expiration Cleaner**: Purges `.asl` text log files older than 7 days (or 2 days for service logs) during daily log maintenance routines.

## What Is NOT Affected

- **Unified Logging (`logd` / `os_log`)**: Modern macOS unified logging, `log show`, `log stream`, Console.app, and system diagnostic reporting operate **100% normally**.
- **System Memory**: Eliminates legacy log rotation daemon, freeing **~8MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.aslmanager 2>/dev/null || true
sudo launchctl disable system/com.apple.aslmanager
```

## Rollback

```bash
sudo launchctl enable system/com.apple.aslmanager
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.aslmanager`.
2. Process `aslmanager` terminated, releasing **~8MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `aslmanager` process remains stopped permanently.
   - Active system process count dropped to **157**.
   - Modern `logd` logging, SSH, networking, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
