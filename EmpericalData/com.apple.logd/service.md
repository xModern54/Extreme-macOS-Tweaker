# Core System Unified Logging Daemon — logd

## Basics

- **Main label:** `system/com.apple.logd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.logd.plist`
- **Binary:** `/usr/libexec/logd`
- **Domain:** `system`
- **Category:** `core_macos_logging_diagnostics`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`logd` (System Logging Daemon) is Apple's primary Unified Logging daemon managing log event streams across the entire operating system:

1. **System Socket Provider (`/var/run/syslog`)**: Listens to `os_log()` and `os_signpost()` API log emissions from all kernel modules, system daemons, user applications, and processes.
2. **Log Stream & Diagnostics Engine (`com.apple.logd`)**: Serves `log show`, `log stream`, and the macOS `Console.app` diagnostic viewer interface.
3. **Kernel Panic Protection (`_PanicOnCrash`)**: Configured with `PanicOnConsecutiveCrash: true`. Terminating `logd` causes an immediate XNU kernel panic.

## Why It Must Remain Enabled

- Disabling `logd` **triggers an immediate kernel panic** and crashes all macOS applications attempting to emit `os_log` trace calls.

## Status

**KEPT ENABLED AND PROTECTED.**
