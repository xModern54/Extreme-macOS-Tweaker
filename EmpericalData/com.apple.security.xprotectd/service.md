# Apple Built-in Background Malware Scanner Daemon — xprotectd

## Basics

- **Main label:** `system/com.apple.security.xprotectd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.security.xprotectd.plist`
- **Binary:** `/usr/libexec/xprotectd`
- **Domain:** `system`
- **Category:** `security_xprotect_antivirus`
- **Risk:** `1` (for power-user / zero-antivirus profiles)
- **Verdict:** `disable for power-user profile`

## What It Does

`xprotectd` (Apple XProtect Malware Scanner Daemon) is Apple's background YARA malware scanning and remediation engine (`XProtectFramework.framework`):

1. **Background File YARA Scanning**: Scans newly downloaded files, unarchived directories, and system paths against Apple YARA signatures (`XProtect.yara`).
2. **Malware Remediation Engine**: Executes periodic background remediation routines (`XProtectRemediatorAdload`, `XProtectRemediatorSnowDrift`, etc.).

## What Is NOT Affected

- **System Permissions & TCC**: Microphone, camera, screen recording, and disk directory access permissions (`tccd`) operate **100% normally**.
- **System Memory & Disk I/O**: Eliminates background file I/O scans, freeing **~16.0MB RSS RAM** and reducing disk activity.

## Disable

```bash
sudo launchctl bootout system/com.apple.security.xprotectd 2>/dev/null || true
sudo launchctl disable system/com.apple.security.xprotectd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.security.xprotectd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.security.xprotectd`.
2. Process `xprotectd` terminated, releasing **~16.0MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 13 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `xprotectd` process remains stopped permanently.
   - Active system process count dropped to **162**.
   - Terminal, Git, VSCode, Docker, SSH, Wi-Fi, and TCC permissions operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
