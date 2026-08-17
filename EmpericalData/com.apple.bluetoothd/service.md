# Bluetooth Radio & Peripheral Subsystem Stack — bluetoothd & Bluetooth Suite

## Basics

- **Main labels:** `system/com.apple.bluetoothd`, `gui/<uid>/com.apple.bluetoothuserd`, `gui/<uid>/com.apple.bluetoothaudiod`, `gui/<uid>/com.apple.bluetoothUIServer`, `system/com.apple.BluetoothUIService`, `system/com.apple.BlueTool`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.bluetoothd.plist`, `/System/Library/LaunchAgents/com.apple.bluetoothuserd.plist`
- **Binaries:** `/usr/sbin/bluetoothd`, `/usr/libexec/bluetoothuserd`
- **Domain:** `system`, `gui/<uid>`
- **Category:** `networking_bluetooth_radio`
- **Risk:** `4` (Causes CoreAudio HAL Log Storm)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`bluetoothd` & the Bluetooth Suite represent Apple's primary Bluetooth radio HCI controller, audio codec, and peripheral pairing stack:

1. **System Hardware Bluetooth HCI Daemon (`com.apple.bluetoothd`)**: Controls the physical Bluetooth radio chip, L2CAP protocol stack, packet logging, and hardware Bluetooth HCI interfaces (~35.8MB RSS RAM).
2. **CoreAudio HAL Integration (`com.apple.BTAudioHALPlugin.xpc`)**: Integrated into `coreaudiod` for Bluetooth audio device discovery and routing.

## Why It Must Remain Enabled (LOG STORM CAUSE)

- Disabling `bluetoothd` **causes an active, high-frequency log storm in `coreaudiod`**: `coreaudiod` repeatedly attempts `bootstrap look-up` for `com.apple.BTAudioHALPlugin.xpc` hundreds of times per second (`XPC server error: Connection invalid`), consuming CPU cycles and flooding system logs.
- Disabling Bluetooth peripherals can be managed safely via system settings or radio sleep, but disabling `com.apple.bluetoothd` at the `launchd` level triggers audio HAL subsystem retry loops.

## Test Result & Discovery

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. Disabled `system/com.apple.bluetoothd` and Bluetooth suite.
2. Real-time log inspection revealed a **launchd log storm**: `coreaudiod` entered a high-frequency retry loop for `com.apple.BTAudioHALPlugin.xpc`.
3. Rollback applied: `bluetoothd` re-enabled and bootstrapped.
4. **Log storm immediately stopped (0 log errors)**.
5. System restored to 100% clean baseline.

## Status

**KEPT ENABLED AND PROTECTED (LOG STORM PREVENTION).**
