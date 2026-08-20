# User Keychain Security Daemon — secd

## Basics

- **Main label:** `gui/<uid>/com.apple.secd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.secd.plist`
- **Binary:** `/usr/libexec/secd`
- **Domain:** `gui/<uid>`
- **Category:** `security_keychain_auth`
- **Risk:** `4` (Critical System Component)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`secd` (Security Daemon) is Apple's per-user Keychain Security daemon:

1. **Keychain Services Engine**: Encrypts, stores, and serves user credentials (`SecItemAdd`, `SecItemCopyMatching`), including Wi-Fi passwords, SSH keys, Git/GitHub tokens, and browser credentials.
2. **XPC Security Services (`com.apple.securityd.xpc`)**: Handles secure credential access requests from all user applications (VSCode, Terminal, Safari, Chrome, Slack, Docker).
3. **Log Noise Mitigation**: Subsystem `com.apple.security.ckks` log noise muted via `sudo log config --mode "level:off" --subsystem com.apple.security.ckks`.

## Why It Must Remain Enabled

- Disabling `secd` breaks all macOS Keychain operations.
- Applications, Git, and terminals lose access to saved tokens and trigger continuous authentication password prompts.

## Status

**KEPT ENABLED AND PROTECTED.**
