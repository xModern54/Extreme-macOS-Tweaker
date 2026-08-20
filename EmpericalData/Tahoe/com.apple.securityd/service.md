# System Security Server Daemon — securityd

## Basics

- **Main label:** `system/com.apple.securityd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.securityd.plist`
- **Binary:** `/usr/sbin/securityd`
- **Domain:** `system`
- **Category:** `auth_security_core`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`securityd` is macOS's low-level System Security Server (`com.apple.SecurityServer`) running in `MinimalBootProfile` mode under root:

1. **System Authentication & sudo Privileges**: Manages `sudo` terminal authentication, Touch ID authorization, and system administration privilege escalation.
2. **System Keychain Management**: Controls `/Library/Keychains/System.keychain` storing root SSL/TLS certificates, Wi-Fi system credentials, and FileVault disk encryption keys.
3. **Secure Memory & Secure Enclave Processor (SEP)**: Allocates protected memory space for administrative master passwords during privileged subsystem calls.

## Why It Must Remain Enabled

- Disabling `securityd` **completely breaks system authentication**, `sudo` terminal commands, Touch ID, and security authorization dialogs across macOS.

## Status

**KEPT ENABLED AND PROTECTED.**
