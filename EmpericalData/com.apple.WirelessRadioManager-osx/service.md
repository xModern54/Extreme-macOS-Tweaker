# Wireless Coexistence & Radio Policy Manager — WirelessRadioManager-osx

## Basics

- **Main label:** `system/com.apple.WirelessRadioManager-osx` (or `com.apple.WirelessRadioManager`)
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.WirelessRadioManager-osx.plist`
- **Binary:** `/usr/sbin/WirelessRadioManagerd`
- **Domain:** `system`
- **Category:** `networking_wireless_coexistence`
- **Risk:** `2-3` (Conditional for Bluetooth audio/peripherals)
- **Verdict:** `KEPT ENABLED FOR BLUETOOTH WORKFLOWS / CANDIDATE FOR NO-BLUETOOTH PROFILE`

## What It Does

`WirelessRadioManagerd` (Wireless Coexistence Manager Daemon) manages Apple Silicon's hardware Wi-Fi and Bluetooth radio coexistence (`com.apple.WirelessCoexManager`):

1. **RF Coexistence Engine**: Dynamically balances radio frequency time slots and antenna transmission power between Wi-Fi (2.4GHz/5GHz/6GHz) and Bluetooth to prevent Wi-Fi data traffic from interfering with Bluetooth audio (AirPods) or wireless input devices (Magic Mouse/Logitech).
2. **Audio & Input Latency Prevention**: Eliminates audio stuttering and mouse lag when downloading heavy network traffic over Wi-Fi.

## Profile Architecture Recommendation

> [!TIP]
> **NO-BLUETOOTH PROFILE CANDIDATE**: `WirelessRadioManagerd` should remain **ENABLED** for standard coding profiles where Bluetooth headphones (AirPods) or wireless mice are used.
> 
> For the future dedicated **`no-bluetooth`** profile (targeting users with wired peripherals or Ethernet/Wi-Fi only), `WirelessRadioManager-osx` is a prime candidate for full deactivation along with `bluetoothreporterd` to eliminate the entire Bluetooth coexistence stack.

## Status

**KEPT ENABLED FOR STANDARD PROFILE.**
