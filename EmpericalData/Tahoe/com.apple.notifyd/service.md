# System IPC Asynchronous Event & Notification Dispatcher — notifyd

## Basics

- **Main label:** `system/com.apple.notifyd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.notifyd.plist`
- **Binary:** `/usr/sbin/notifyd`
- **Domain:** `system`
- **Category:** `core_macos_event_dispatch`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`notifyd` (System Notification Server) is Apple's central IPC asynchronous event and notification dispatching daemon (`notify(3)` / `libsystem_notify.dylib` / `com.apple.system.notification_center`):

1. **System IPC Event Bus Dispatcher (`notify_post` / `notify_register_dispatch`)**: Serves as the central nerve system for macOS IPC event propagation. Receives and dispatches system state notifications (network changes, power events, screen lock/unlock transitions, mount events, launchd triggers) across all processes.
2. **`launchd` & `UserEventAgent` LaunchEvent Engine**: Powers event matching channels (`com.apple.notifyd.matching`) relied upon by `launchd` for on-demand job activation.

## Why It Must Remain Enabled

- Disabling `notifyd` **instantly panics the XNU kernel and crashes all macOS user and system processes due to loss of the central IPC event bus**.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
