# CoreFoundation Preferences Management Daemon — cfprefsd

## Basics

- **Main labels:** `gui/<uid>/com.apple.cfprefsd.xpc.daemon`, `system/com.apple.cfprefsd.xpc.daemon`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.cfprefsd.xpc.daemon.plist`, `/System/Library/LaunchDaemons/com.apple.cfprefsd.xpc.daemon.plist`
- **Binary:** `/usr/sbin/cfprefsd`
- **Domain:** `gui/<uid>`, `system`, `user/<uid>`
- **Category:** `core_macos_preferences`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`cfprefsd` (CoreFoundation Preferences Daemon) is Apple's primary system and user preference caching and persistence daemon:

1. **CFPreferences Caching & Persistence Engine (`~/Library/Preferences/`)**: Manages reading, memory caching, and writing of all `.plist` configuration files across macOS for all applications and system services (`defaults read/write`, `CFPreferencesCopyAppValue`).
2. **Preference Transaction Protection**: Maintains in-memory preference caches to minimize disk I/O and prevent preference file corruption during application updates.

## Why It Must Remain Enabled

- Disabling `cfprefsd` **completely crashes the operating system and all applications**: Every process on macOS freezes or crashes immediately upon attempting to read or write any configuration setting.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
