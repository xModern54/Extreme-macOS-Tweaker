# Hardware Repair Verification & Calibration System Daemon — corerepaird

## Basics

- **Main label:** `system/com.apple.corerepaird`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.corerepaird.plist`
- **Binary:** `/usr/libexec/corerepaird`
- **Domain:** `system`
- **Category:** `hardware_repair_verification`
- **Risk:** `1` (for standard coding workflows)
- **Verdict:** `disable for coding profile`

## What It Does

`corerepaird` (Core Repair System Daemon) is Apple's root system daemon for hardware component genuine verification and repair calibration (`CoreRepair.framework`):

1. **System Hardware Component Cryptographic Auditor**: Queries factory authentication microchips on replaced MacBook components (display, battery, trackpad, cameras, logic board) to verify Apple genuine component signatures.
2. **System Companion to `mobilerepaird`**: Serves as the root-level system daemon counterpart to `mobilerepaird` (which was previously disabled).

## What Is NOT Affected

- **Touch ID, Display, Battery, Wi-Fi & System Hardware**: Hardware authentication via Secure Enclave (`AppleSEPManager`), display brightness, Touch ID sudo authentication, trackpad gestures, Wi-Fi, Bluetooth, Terminal, Git, VSCode, Docker, SSH, and audio operate **100% normally**.
- **System Memory**: Eliminates persistent root daemon, freeing **~15MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.corerepaird 2>/dev/null || true
sudo launchctl disable system/com.apple.corerepaird
```

## Rollback

```bash
sudo launchctl enable system/com.apple.corerepaird
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.corerepaird`.
2. Process `corerepaird` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `corerepaird` process remains stopped permanently.
   - Active system process count dropped to **158**.
   - Touch ID, display brightness, hardware functions, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
