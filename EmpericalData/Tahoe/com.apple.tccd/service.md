# Privacy & Permissions Enforcement Daemon — tccd

## Basics

- **Main labels:** `gui/<uid>/com.apple.tccd`, `system/com.apple.tccd.system`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.tccd.plist`, `/System/Library/LaunchDaemons/com.apple.tccd.system.plist`
- **Binary:** `/System/Library/PrivateFrameworks/TCC.framework/Support/tccd`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `security_tcc_privacy_permissions`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`tccd` (Transparency, Consent, and Control Daemon) is Apple's per-user and per-system privacy permissions enforcement daemon managing `TCC.db`:

1. **System Privacy Permissions Engine**: Controls application entitlement checks and user consent dialogs for **Camera, Microphone, Screen Recording, Full Disk Access, File System Access (`~/Desktop`, `~/Documents`), Location Services, and Accessibility**.
2. **TCC Database Management**: Reads and updates active privacy permission records in `~/Library/Application Support/com.apple.TCC/TCC.db` and `/Library/Application Support/com.apple.TCC/TCC.db`.

## Why It Must Remain Enabled

- Disabling `tccd` **completely breaks application file disk access**, screen recording in video conference software (Zoom, Discord, OBS), terminal file access, and camera/microphone permissions across macOS.

## Status

**KEPT ENABLED AND PROTECTED.**
