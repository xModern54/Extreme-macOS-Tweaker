# Device Management & ScreenTime Policy Engine — dmd

## Basics

- **Main labels:** `gui/<uid>/com.apple.dmd`, `system/com.apple.dmd`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.dmd.agent.plist`, `/System/Library/LaunchDaemons/com.apple.dmd.plist`
- **Binary:** `/usr/libexec/dmd`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `device_management_mdm`
- **Risk:** `1` (for non-managed personal Macs)
- **Verdict:** `disable for coding profile`

## What It Does

`dmd` (Device Management Daemon) is Apple's background engine for Mobile Device Management (MDM) and ScreenTime policy enforcement:

1. **Screen Time Restrictions (`ManagedSettings`)**: Evaluates daily application usage budgets, website domain limits, and shield UI overlays (*"App Limit Reached"*).
2. **MDM Command Processing**: Processes remote management commands from corporate MDM servers (Jamf, Kandji, Intune) for enrolled devices.
3. **Emergency Security Mode**: Enforces system-wide security policy overrides.

## What Is NOT Affected

- **System Boot Integrity & Security**: macOS bootloader, SIP, SSV, FileVault encryption, `securityd`, `trustd`, and `syspolicyd` operate **100% normally**.
- **Developer Tools & Applications**: Terminal, VSCode, Git, Docker, SSH, Wi-Fi, sound, browsers, and graphics run without any degradation.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.dmd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.dmd"
sudo launchctl bootout system/com.apple.dmd 2>/dev/null || true
sudo launchctl disable system/com.apple.dmd
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.dmd"
sudo launchctl enable system/com.apple.dmd
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502` and `system` domains.
2. Process `dmd` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `dmd` process remains stopped.
   - Boot integrity and system stability remain 100% intact.
   - Log audit confirmed 0 errors or retry loops.
