# Quarantine Dialog & App Security Alert UI Agent — CoreServicesUIAgent

## Basics

- **Main label:** `gui/<uid>/com.apple.coreservices.uiagent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.coreservices.uiagent.plist`
- **Binary:** `/System/Library/CoreServices/CoreServicesUIAgent.app/Contents/MacOS/CoreServicesUIAgent`
- **Domain:** `gui/<uid>`
- **Category:** `security_quarantine_ui`
- **Risk:** `1` (for power-user / unverified app execution profiles)
- **Verdict:** `disable for power-user profile`

## What It Does

`CoreServicesUIAgent` is Apple's primary UI agent for rendering Quarantine and Gatekeeper dialog popups (`LaunchServices` / `Quarantine.framework`):

1. **Quarantine Warning Popups**: Renders dialogs such as *"App was downloaded from the Internet. Are you sure you want to open it?"*.
2. **Unverified App Alerts**: Renders Gatekeeper block dialogs for unsigned or unverified applications.

## What Is NOT Affected

- **System Permissions & TCC**: Microphone, camera, screen recording, and disk directory access permissions (`tccd`) operate **100% normally**.
- **Normal App Execution**: Opening applications operates smoothly without nag popups.
- **System Memory**: Reclaims **~34.8MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.coreservices.uiagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.coreservices.uiagent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.coreservices.uiagent"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.coreservices.uiagent`.
2. Process `CoreServicesUIAgent` terminated, releasing **~34.8MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `CoreServicesUIAgent` process remains stopped permanently.
   - Active system process count dropped to **160**.
   - App launches, Terminal, Git, VSCode, Docker, SSH, Wi-Fi, and TCC permissions operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
