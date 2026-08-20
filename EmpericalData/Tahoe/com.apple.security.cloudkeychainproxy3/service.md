# iCloud Keychain Syncing Proxy — cloudkeychainproxy3

## Basics

- **Main label:** `gui/<uid>/com.apple.security.cloudkeychainproxy3`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.security.cloudkeychainproxy3.plist`
- **Binary:** `/System/Library/Frameworks/Security.framework/cloudkeychainproxy3.app/Contents/MacOS/cloudkeychainproxy3`
- **Domain:** `gui/<uid>`
- **Category:** `icloud_keychain_sync`
- **Risk:** `1` (for local-only coding profile) / `2` (Conditional for iCloud Keychain users)
- **Verdict:** `disable for coding profile`

## What It Does

`cloudkeychainproxy3` (Cloud Keychain Proxy) is Apple's iCloud Keychain password and credentials sync proxy agent:

1. **iCloud Keychain Synchronization**: Handles real-time syncing of saved Web/App passwords, passkeys, and credit card autofill entries between Apple devices over iCloud (`Security.framework`).
2. **Cloud Keychain Event Handler**: Responds to local keybag unlock notifications (`com.apple.mobile.keybagd.first_unlock`) to trigger credential sync queues.

## What Is NOT Affected

- **Local Keychain & Password Saving**: Local Keychain Access, saved SSH keys, local application passwords, VSCode, Terminal, Git, Docker, and SSH operate **100% normally**.
- **System Memory**: Eliminates background iCloud Keychain sync proxy.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.security.cloudkeychainproxy3" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.security.cloudkeychainproxy3"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.security.cloudkeychainproxy3"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.security.cloudkeychainproxy3`.
2. Agent disabled in launchd.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed 0 errors or retry loops.
