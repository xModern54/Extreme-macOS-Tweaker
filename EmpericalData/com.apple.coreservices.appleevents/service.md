# AppleEvents & AppleScript Inter-Process Automation Daemon — appleeventsd

## Basics

- **Main label:** `system/com.apple.coreservices.appleevents`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.coreservices.appleevents.plist`
- **Binary:** `/System/Library/CoreServices/appleeventsd`
- **Domain:** `system`
- **Category:** `core_macos_automation_applescript_events`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`appleeventsd` (AppleEvents Daemon) is Apple's primary inter-process event routing and automation daemon:

1. **AppleEvents Message Routing (`com.apple.coreservices.appleevents`)**: Manages IPC messaging and event dispatching between macOS applications.
2. **AppleScript & `osascript` Engine**: Powers execution of AppleScript, JavaScript for Automation (JSA), `osascript` command-line tools, Shortcuts app automation, Raycast/Alfred extensions, and IDE build scripts.

## Why It Must Remain Enabled

- Disabling `appleeventsd` **completely breaks AppleScript execution**, `osascript` commands, Shortcuts application workflows, IDE build automation, and inter-app scripting with error `-1708` (`errAEEventNotHandled`).

## Status

**KEPT ENABLED AND PROTECTED.**
