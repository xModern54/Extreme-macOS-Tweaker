# Cryptographic OS Component & Dynamic Cryptex Manager — cryptexd

## Basics

- **Main label:** `system/com.apple.security.cryptexd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.security.cryptexd.plist`
- **Binary:** `/usr/libexec/cryptexd`
- **Domain:** `system`
- **Category:** `auth_security_cryptex_os`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`cryptexd` (Cryptex Security Daemon) is Apple's primary Cryptex cryptographic volume and dynamic system extension manager (`Cryptex.framework` / SSV / RSR):

1. **Cryptographic System Cryptex Mount Engine (`/private/var/run/com.apple.security.cryptexd/`)**: Unpacks, verifies cryptographic signatures, and mounts Cryptex OS containers (`system_os`, `app_os`) housing Safari/WebKit engines, dynamic security patches, and framework libraries.
2. **Signed System Volume (SSV) Support**: Enables rapid security response (RSR) patches and dynamic OS extensions without modifying the read-only Signed System Volume (SSV).

## Why It Must Remain Enabled

- Disabling `cryptexd` **completely breaks Safari, WebKit, system utilities, and dynamic OS extensions across macOS**, causing system applications to crash and rendering macOS unbootable.
- Explicitly protected in `AGENTS.md` core security guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
