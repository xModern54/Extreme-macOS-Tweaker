# com.apple.DriverKit-AppleBCMWLAN

## Basics

- **Process names:** `com.apple.DriverKit-AppleBCMWLAN`
- **Domain:** `driverkit (DriverExtensions)`
- **Bundle Path:** `/System/Library/DriverExtensions/com.apple.DriverKit-AppleBCMWLAN.dext`
- **Binary:** `/System/Library/DriverExtensions/com.apple.DriverKit-AppleBCMWLAN.dext/com.apple.DriverKit-AppleBCMWLAN`
- **Category:** `hardware_wifi_driverkit`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Broadcom / Apple Wireless LAN Driver Extension (DEXT).
In modern macOS (Apple Silicon / DriverKit architecture), hardware drivers run in isolated userspace under system user `_driverkit` rather than kernel space (KEXT).
This process is the **actual physical Wi-Fi hardware driver** for the Broadcom/Apple wireless chip (PCIe / Bus interface, firmware loading, frame transmission, WPA3/Wi-Fi 6E/7 protocol handling).

Why we looked at it:
Found running in process table under user `_driverkit`.

Resource footprint:
~37 MB virtual / working RAM, CPU idle ~0.0–1.0% during network traffic.

Needed for coding / system:
Yes. Required for any physical Wi-Fi wireless connectivity. Disabling or killing it completely disables the Wi-Fi adapter ("No Wi-Fi Hardware Installed").

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4)**.
Core hardware driver for physical Wi-Fi networking.
