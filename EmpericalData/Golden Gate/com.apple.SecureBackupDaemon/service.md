# com.apple.SecureBackupDaemon

## Basics

- **Process names:** `com.apple.sbd`, `sbd`
- **Domain:** `gui/<uid>`
- **Plist:** `/System/Library/LaunchAgents/com.apple.SecureBackupDaemon.plist`
- **Binary:** `/System/Library/PrivateFrameworks/CloudServices.framework/Helpers/com.apple.sbd`
- **Category:** `icloud_keychain_secure_backup`
- **Risk:** `1`
- **Verdict:** `disable`

## Notes

What it does:
Secure Backup Daemon (`sbd` / `CloudServices.framework`).
Responsible for:
1. **iCloud Keychain End-to-End Encryption Escrow**: Synchronizes and backs up encrypted Keychain records to Apple's CloudServices secure escrow servers.
2. **Account Recovery Key Escrow**: Handles cryptographic backup of device recovery tokens for Apple ID multi-device keychain recovery.
3. Listens for `com.apple.security.itembackup` notifications from `notifyd`.

Why we looked at it:
Found running in user session on macOS 27 Golden Gate.

Resource footprint:
~6.0 MB RAM, 0.0% CPU.

Needed for coding / system:
No. Local Keychain storage (`login.keychain-db`) and local password management work 100% normally. Required only if using iCloud Keychain sync across multiple Apple devices.

Disable:
```bash
launchctl bootout gui/<uid>/com.apple.SecureBackupDaemon
launchctl disable gui/<uid>/com.apple.SecureBackupDaemon
```

Rollback:
```bash
launchctl enable gui/<uid>/com.apple.SecureBackupDaemon
launchctl bootstrap gui/<uid> /System/Library/LaunchAgents/com.apple.SecureBackupDaemon.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely booted out and disabled. Local keychain and system operation completely normal.
Verdict: **SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE FOR ICLOUD TWEAKS (Risk 1)**.
