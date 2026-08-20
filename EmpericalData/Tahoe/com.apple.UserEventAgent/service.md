# Core System Event Dispatcher & Launchd Event Host — UserEventAgent

## Basics

- **Main labels:** `gui/<uid>/com.apple.UserEventAgent-Aqua`, `system/com.apple.UserEventAgent-System`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.UserEventAgent-Aqua.plist`, `/System/Library/LaunchDaemons/com.apple.UserEventAgent-System.plist`
- **Binary:** `/usr/libexec/UserEventAgent`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `system_event_dispatcher`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`UserEventAgent` is Apple's primary system event plugin host and `launchd` event dispatcher:

1. **System Event Plugin Host (`UserEventAgent.plugin`)**: Loads and executes core event monitoring plugins for external drive mounting/unmounting (USB/Thunderbolt), power state changes (battery/AC), sleep/wake transitions (DarkWake), external display connections, and network interface state changes.
2. **Launchd Event Dispatcher (`LaunchEvents` / `FSEvents`)**: Serves as `launchd`'s event trigger observer, monitoring filesystem changes, IOKit hardware events, and Mach notification channels to trigger dependent system daemons.

## Why It Must Remain Enabled

- Disabling `UserEventAgent` **completely breaks macOS hardware event handling and launchd event triggers**: The system loses drive auto-mounting, sleep/wake event handling, power state monitoring, and `launchd` event dispatching.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
