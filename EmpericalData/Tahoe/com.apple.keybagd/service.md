# APFS Data Protection & System Keybag Encryption Daemon — keybagd

## Basics

- **Main label:** `system/com.apple.mobile.keybagd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.mobile.keybagd.plist`
- **Binary:** `/usr/libexec/keybagd`
- **Domain:** `system`
- **Category:** `auth_security_keybag_apfs`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`keybagd` (Mobile Keybag Daemon) is Apple's primary APFS Data Protection and disk keybag encryption daemon:

1. **APFS Disk Decryption Engine on First Unlock (`first_unlock`)**: Unlocks and delivers master encryption keys (Keybag) to the XNU kernel upon user login (`com.apple.mobile.keybagd.first_unlock`) and screen unlock (password/Touch ID).
2. **Data Protection Class Key Manager**: Coordinates file encryption class key lock/unlock transitions during sleep, wake, and screen lock events.

## Why It Must Remain Enabled

- Disabling `keybagd` **completely breaks user authentication, screen unlock, and APFS encrypted disk file access across macOS**: Systems become impossible to unlock post-boot.
- Explicitly protected in `AGENTS.md` core security guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
