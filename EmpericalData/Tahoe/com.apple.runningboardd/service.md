# Core Process Lifecycle & App Assertion Daemon — runningboardd

## Basics

- **Main label:** `system/com.apple.runningboardd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.runningboardd.plist`
- **Binary:** `/usr/libexec/runningboardd`
- **Domain:** `system`
- **Category:** `core_macos_process_lifecycle`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`runningboardd` (RunningBoard Daemon) is Apple's primary process lifecycle state and resource assertion manager:

1. **Application Lifecycle Management (`com.apple.runningboard`)**: Transitions applications between `Foreground`, `Background`, `Suspended`, and `Terminated` states.
2. **App Extension & XPC Lifecycle Management**: Coordinates execution assertions for App Extensions, AppIntents, and helper services.
3. **Resource Priority & Jetsam Allocation (`resource_notify`)**: Allocates CPU priorities, memory limits, and process coalition states to AppKit UI applications.

## Why It Must Remain Enabled

- Disabling `runningboardd` **completely breaks application lifecycle management**: UI apps cannot focus, background process states collapse, and new application launches are blocked.

## Status

**KEPT ENABLED AND PROTECTED.**
