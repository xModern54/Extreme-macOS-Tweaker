# Hardware Liquid Ingress Detection & Emergency Power Disconnect Daemon — liquiddetectiond

## Basics

- **Main label:** `system/com.apple.liquiddetectiond`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.liquiddetectiond.plist`
- **Binary:** `/System/Library/CoreServices/liquiddetectiond.app/liquiddetectiond`
- **Domain:** `system`
- **Category:** `hardware_safety_liquid_detection`
- **Risk:** `4` (Critical Hardware Safety Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`liquiddetectiond` (Liquid Detection Daemon) is Apple's hardware liquid ingress detection and emergency port disconnect daemon:

1. **USB-C / Thunderbolt Port Moisture Sensor Monitor (`LiquidDetected`)**: Monitors hardware resistance and humidity sensors in USB-C / Thunderbolt ports (`IOPortFeatureLDCM`).
2. **Emergency Port Power Cutoff**: Instantly cuts power to affected USB-C ports upon detecting moisture/water ingress, rendering safety notifications (*"Charging Unavailable: Liquid Detected in Connector"*) to protect power management ICs from short-circuit damage.

## Why It Must Remain Enabled

- Disabling `liquiddetectiond` **completely disables hardware liquid safety protection for USB-C ports**: Accidental liquid spills inside ports risk severe short circuits, motherboard damage, and power controller destruction.
- Explicitly protected in `AGENTS.md` core security guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
