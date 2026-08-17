# CoreCDP iCloud Keychain End-to-End Encryption Daemon — cdpd

## Basics

- **Main label:** `gui/<uid>/com.apple.cdpd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.cdpd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/CoreCDP.framework/Versions/A/Resources/cdpd`
- **Domain:** `gui/<uid>`
- **Category:** `system_accounts_icloud_cdp_keychain`
- **Risk:** `2` (conditional for profiles removing iCloud syncing)
- **Verdict:** `disable for coding profile without iCloud Keychain`

## What It Does

`cdpd` (CoreCDP Daemon) manages Apple's Core Circle Data Protection framework:

1. **iCloud Keychain End-to-End Encryption (`Octagon` / `circlechanged`)**: Manages the circle of trust across Apple devices for decrypting iCloud Keychain passwords and Advanced Data Protection keys.
2. **Device Authentication Alerts**: Displays security prompts requesting password confirmation from other Apple devices.

## What Is NOT Affected

- **Local Keychain & Password Auth**: Local Keychain password storage, Touch ID, SSH keys (`id_ed25519`), Git, VSCode, Terminal, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates background daemon, freeing **~16MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.cdpd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.cdpd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.cdpd"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.cdpd`.
2. Process `cdpd` terminated, releasing **~16MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `cdpd` process remains stopped.
   - Local Keychain, Touch ID, SSH keys, and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
