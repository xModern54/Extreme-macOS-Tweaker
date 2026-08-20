# Handoff & Universal Clipboard — useractivityd

## Basics

- **Main labels:** `com.apple.coreservices.useractivityd`, `com.apple.useractivityd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.coreservices.useractivityd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/UserActivity.framework/Agents/useractivityd`
- **Domain:** `gui/<uid>`
- **Category:** `icloud_continuity_handoff`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`useractivityd` is Apple's background Continuity agent responsible for:

1. **Handoff (`NSUserActivity`)**:
   - Publishes and broadcasts user activity state between iOS and macOS devices, enabling single-click transition of active web pages, notes, or emails via Dock icons.

2. **Universal Clipboard**:
   - Encrypts and syncs clipboard contents across Apple devices signed into the same iCloud account via Bluetooth LE, `sharingd`, and `rapportd`.

## What Is NOT Affected

- **Local macOS Clipboard (`pboard`)**: Standard copy/paste (`Cmd+C` / `Cmd+V`) within macOS operates via `/usr/libexec/pboard` and remains **100% functional**.
- **System Stability & Developer Tools**: Local apps, terminal, VSCode, Git, Docker, Wi-Fi, SSH, and networking operate without any degradation.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.coreservices.useractivityd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.coreservices.useractivityd"
launchctl disable "gui/$uid/com.apple.useractivityd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.coreservices.useractivityd"
launchctl enable "gui/$uid/com.apple.useractivityd"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. Disabled `gui/502/com.apple.coreservices.useractivityd` and `gui/502/com.apple.useractivityd`.
2. Process `useractivityd` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 13 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `useractivityd` process remains stopped.
   - Local macOS clipboard (`Cmd+C` / `Cmd+V`) operates normally via `pboard`.
   - Log audit confirmed 0 errors or retry loops.
