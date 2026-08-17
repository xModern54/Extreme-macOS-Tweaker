# Core Wi-Fi & Wireless Controller Daemon — airportd

## Basics

- **Main label:** `system/com.apple.airportd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.airportd.plist`
- **Binary:** `/usr/libexec/airportd`
- **Domain:** `system`
- **Category:** `networking_wifi_wireless_airport`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`airportd` (AirPort Wireless Daemon) is Apple's primary low-level Wi-Fi controller and network management daemon:

1. **Hardware Wi-Fi Controller Management (`IO80211Controller`)**: Controls the physical Wi-Fi network interface, handles 802.11a/b/g/n/ac/ax/be radio scanning, WPA2/WPA3 authentication, and automatic access point roaming.
2. **CoreWLAN XPC API Provider (`com.apple.corewlan-xpc` / `com.apple.wifi-xpc`)**: Serves Wi-Fi status, signal strength, and network connection requests across all macOS system components.

## Why It Must Remain Enabled

- Disabling `airportd` **completely disables all Wi-Fi networking on macOS**: The Mac immediately loses the ability to scan, connect to, or maintain Wi-Fi internet connections.
- Explicitly protected in `AGENTS.md` core networking guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
