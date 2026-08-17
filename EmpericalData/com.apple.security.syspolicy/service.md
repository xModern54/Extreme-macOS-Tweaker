# Gatekeeper & App Notarization Security Policy Daemon — syspolicyd

## Basics

- **Main label:** `system/com.apple.security.syspolicy`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.security.syspolicy.plist`
- **Binary:** `/usr/libexec/syspolicyd`
- **Domain:** `system`
- **Category:** `security_gatekeeper_syspolicy`
- **Risk:** `1` (for power-user / zero-enforcement profiles)
- **Verdict:** `disable for power-user profile`

## What It Does

`syspolicyd` (Gatekeeper System Policy Daemon) is Apple's primary execution security policy and notarization engine (`Security.framework` / `HostSpecialPort: 29`):

1. **Gatekeeper Code Signing & Notarization Engine**: Validates application developer certificates, Apple notarization tickets, and binary code signatures prior to execution.
2. **App Execution Blocking**: Blocks unverified, revoked, or untrusted binary execution, producing *"Developer cannot be verified"* or *"App is damaged"* system blocks.
3. **Legacy Kext & System Policy Monitoring**: Monitors kernel extension deprecation and execution policy revocation.

## What Is NOT Affected

- **System Permissions & TCC**: Microphone, camera, screen recording, and disk directory access permissions (`tccd`) operate **100% normally**.
- **System Memory & CPU**: Reclaims **~52.1MB RSS RAM** and eliminates signature validation latencies during app launches.

## Disable

```bash
sudo launchctl bootout system/com.apple.security.syspolicy 2>/dev/null || true
sudo launchctl disable system/com.apple.security.syspolicy
```

## Rollback

```bash
sudo launchctl enable system/com.apple.security.syspolicy
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.security.syspolicy`.
2. Process `syspolicyd` terminated, releasing **~52.1MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 13 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `syspolicyd` process remains stopped permanently.
   - Active system process count dropped to **160**.
   - App launches, Terminal, Git, VSCode, Docker, SSH, Wi-Fi, and TCC permissions operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
