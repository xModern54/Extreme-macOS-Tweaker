# Hardware & Kernel Watchdog Hang Protection Daemon — watchdogd

## Basics

- **Main label:** `system/com.apple.watchdogd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.watchdogd.plist`
- **Binary:** `/usr/libexec/watchdogd`
- **Domain:** `system`
- **Category:** `hardware_kernel_watchdog`
- **Risk:** `4` (Critical System Safety Infrastructure — Kernel Panic Trigger)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`watchdogd` (Hardware Watchdog Daemon) is Apple's root hardware watchdog and kernel hang detection daemon (`IOWatchdog` / `Watchdog.framework`):

1. **Hardware Watchdog Timer Reset Engine (`IOWatchdog`)**: Interacts directly with the `IOWatchdog` kernel driver, periodically resetting hardware watchdog timers. If the XNU kernel or critical services freeze, hardware timer resets cease, prompting an automated hardware reset to recover frozen Mac hardware.
2. **`PanicOnCrash` Directive**: Enforces `PanicOnConsecutiveCrash: true` within its `launchd` manifest to mandate kernel panic recovery if watchdog monitoring is disrupted.

## Why It Must Remain Enabled

- Disabling `watchdogd` **instantly triggers an XNU Kernel Panic and forces a system reboot** due to hardware `IOWatchdog` safety timers expiring.
- Explicitly protected in `AGENTS.md` core kernel guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
