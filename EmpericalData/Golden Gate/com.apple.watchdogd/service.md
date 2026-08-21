# com.apple.watchdogd

## Basics

- **Process names:** `watchdogd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.watchdogd.plist`
- **Binary:** `/usr/libexec/watchdogd`
- **Category:** `hardware_kernel_watchdog`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Hardware & Kernel Watchdog Hang Protection Daemon (`watchdogd` / `IOWatchdog`).
Interfaces directly with the Apple Silicon hardware PMU / SMC watchdog timer register.
Responsible for:
1. **Hardware Watchdog Tick Reset**: Periodically resets the hardware watchdog countdown timer in the SoC power management unit.
2. **Panic on Consecutive Crash**: Configured with `PanicOnConsecutiveCrash: true` in launchd. If `watchdogd` is killed, disabled, or fails to tick the timer, the hardware timer expires and triggers an automatic SoC hardware reboot / kernel panic.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `watchdogd` **immediately triggers an XNU Kernel Panic and forces an emergency hardware reboot** when the unserviced hardware watchdog timer trips.

Resource footprint:
~2.7 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Absolutely mandatory low-level hardware watchdog protection daemon.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Hardware Watchdog & Kernel Panic Trigger)**.
