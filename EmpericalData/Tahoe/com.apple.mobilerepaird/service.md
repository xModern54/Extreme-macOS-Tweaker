# Mobile Hardware Component Repair Verification Agent — mobilerepaird

## Basics

- **Main label:** `gui/<uid>/com.apple.mobilerepaird`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.mobilerepaird.plist`
- **Binary:** `/usr/libexec/mobilerepaird`
- **Domain:** `gui/<uid>`
- **Category:** `hardware_repair_diagnostics`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`mobilerepaird` (Mobile Repair Verification Agent) is Apple's hardware component cryptographic authentication and diagnostic reporting agent:

1. **Replaced Hardware Component Certificate Verification (`isTrustedForUI`)**: Queries internal hardware pairing chips (battery, display, lid angle sensor) for genuine Apple certificates and renders service warning banners under *System Settings -> General -> About*.
2. **Component Repair Daily Telemetry**: Collects daily status reports regarding replacement hardware module authentication.

## What Is NOT Affected

- **Physical Hardware Functionality**: Display, screen brightness, battery charging, lid angle sensor, keyboard, trackpad, VSCode, Terminal, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates persistent GUI agent, freeing **~15MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.mobilerepaird" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.mobilerepaird"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.mobilerepaird"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.mobilerepaird`.
2. Process `mobilerepaird` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `mobilerepaird` process remains stopped permanently.
   - All physical hardware components (display, battery, lid sensor) operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
