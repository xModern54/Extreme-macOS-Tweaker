# Protected Cloud Storage (PCS) Key Sync Agent — protectedcloudkeysyncing

## Basics

- **Main label:** `gui/<uid>/com.apple.protectedcloudstorage.protectedcloudkeysyncing`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.protectedcloudstorage.protectedcloudkeysyncing.plist`
- **Binary:** `/System/Library/PrivateFrameworks/ProtectedCloudStorage.framework/Helpers/protectedcloudkeysyncing`
- **Domain:** `gui/<uid>`
- **Category:** `icloud_keychain_sync`
- **Risk:** `1` (for local-only coding profile) / `2` (Conditional for multi-device iCloud users)
- **Verdict:** `disable for coding profile`

## What It Does

`protectedcloudkeysyncing` (Protected Cloud Storage Key Syncing Agent) is Apple's CloudKit PCS key escrow and synchronization agent:

1. **iCloud PCS Key Synchronization**: Manages backup and synchronization of encrypted Protected Cloud Storage (PCS) keys to CloudKit across registered user Apple IDs.
2. **CloudKit Key Recovery**: Handles secure recovery escrow of PCS key material.

## What Is NOT Affected

- **Local File System & Local Keychain**: Local disk encryption, local Keychain Access passwords, VSCode, Terminal, Git, Docker, SSH, and network operate **100% normally**.
- **System Memory**: Eliminates background CloudKit PCS key sync agent.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.protectedcloudstorage.protectedcloudkeysyncing" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.protectedcloudstorage.protectedcloudkeysyncing"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.protectedcloudstorage.protectedcloudkeysyncing"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.protectedcloudstorage.protectedcloudkeysyncing`.
2. Agent disabled in launchd.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed 0 errors or retry loops.
