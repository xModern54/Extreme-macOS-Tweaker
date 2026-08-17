# Battery Peak Power Management & Unexpected Shutdown Prevention Daemon — peakpowermanagerd

## Basics

- **Main label:** `system/com.apple.peakpowermanagerd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.peakpowermanagerd.plist`
- **Binary:** `/usr/libexec/peakpowermanagerd`
- **Domain:** `system`
- **Category:** `hardware_power_management_battery`
- **Risk:** `4` (Critical Hardware Safety Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`peakpowermanagerd` (Peak Power Manager Daemon) is Apple's battery peak power management and unexpected shutdown prevention daemon (`PowerManagement.framework`):

1. **Battery Peak Power Management Engine**: Monitors battery health, state-of-charge (SOC), and internal cell impedance. Dynamically caps peak CPU/GPU power draw spikes when operating on battery power to prevent sudden voltage drops.
2. **Unexpected Shutdown Prevention**: Protects MacBook hardware from sudden powering-off during heavy workload bursts (e.g. heavy code compilation or Docker builds) on low battery levels.

## Why It Must Remain Enabled

- Disabling `peakpowermanagerd` **exposes the MacBook to sudden unexpected power-offs during heavy CPU/GPU compilation workloads when running on low battery power**.
- Explicitly protected in `AGENTS.md` core hardware power guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
