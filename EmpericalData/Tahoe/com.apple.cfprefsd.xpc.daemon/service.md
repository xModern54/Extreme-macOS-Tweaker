# Core Preferences Daemon — cfprefsd

## Basics

- **Main labels:** `system/com.apple.cfprefsd.xpc.daemon`, `gui/<uid>/com.apple.cfprefsd.xpc.agent`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.cfprefsd.xpc.daemon.plist`, `/System/Library/LaunchAgents/com.apple.cfprefsd.xpc.agent.plist`
- **Binary:** `/usr/sbin/cfprefsd`
- **Domain:** `system`, `gui/<uid>`
- **Category:** `core_macos_preferences_cfpreferences`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`cfprefsd` (CoreFoundation Preferences Daemon) is Apple's fundamental preference reading, caching, and writing service:

1. **`NSUserDefaults` & `CFPreferences` Engine**: Serves all IPC preferences read/write queries across every application, framework, and daemon in macOS.
2. **Atomic `.plist` Persistence**: Manages atomic disk commits for configuration plists in `~/Library/Preferences/` and `/Library/Preferences/`.

## Why It Must Remain Enabled

- Disabling `cfprefsd` **instantly crashes all macOS applications and system services**, preventing preference reading, UI initialization, and process launches.
- Explicitly listed as a protected core component in `AGENTS.md`.

## Status

**KEPT ENABLED AND PROTECTED.**
