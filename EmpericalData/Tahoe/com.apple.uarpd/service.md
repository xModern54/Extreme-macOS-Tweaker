# Universal Accessory Reflash Protocol — uarpd

## Basics

- **Main label:** `system/com.apple.uarpd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.uarpd.plist`
- **Binary:** `/usr/libexec/uarpd`
- **Domain:** `system`
- **User:** `_accessoryupdater`
- **Category:** `accessory_firmware_updates`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`uarpd` (Universal Accessory Reflash Protocol Daemon) is Apple's system background service for updating firmware payloads on connected Apple physical accessories:

1. **AirPods & Beats Firmware Updating**: Downloads and flashes silent background firmware updates to AirPods/Beats over Bluetooth LE.
2. **MagSafe & USB-C Cable/Adapter Firmware**: Flashes power management and video controller firmware in Apple MagSafe 3 ports, USB-C Digital AV Multiport adapters, and Thunderbolt cables.
3. **Magic Keyboard / Mouse / Trackpad Firmware**: Downloads security patches for Apple Bluetooth peripherals.

## What Is NOT Affected

- **AirPods / Beats Audio & Bluetooth Functionality**: Audio playback, pairing, and connection work **100% normally**. (AirPods continue receiving firmware updates via iPhone/iPad upon normal usage).
- **Magic Keyboard / Mouse / Trackpad Functionality**: All Apple Bluetooth peripherals operate without issues.
- **USB-C Displays & MagSafe Charging**: Display output and battery charging operate normally.

## Disable

```bash
sudo launchctl bootout system/com.apple.uarpd 2>/dev/null || true
sudo launchctl disable system/com.apple.uarpd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.uarpd
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.uarpd`.
2. Process `uarpd` terminated, releasing **~10MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `uarpd` process remains stopped.
   - Bluetooth audio, AirPods playback, Magic Mouse, and USB-C adapters operate without issues.
   - Log audit confirmed 0 errors or retry loops.
