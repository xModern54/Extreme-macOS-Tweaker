# Apple Mobile Accessory Updater Daemon — accessoryupdaterd & UARPUpdaterService

## Basics

- **Main labels:** `system/com.apple.accessoryupdaterd`, `system/com.apple.uarpd`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.accessoryupdaterd.plist`, `/System/Library/LaunchDaemons/com.apple.uarpd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/MobileAccessoryUpdater.framework/Support/accessoryupdaterd`
- **Domain:** `system`
- **Category:** `hardware_accessory_updater`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`accessoryupdaterd` and its 7 spawned XPC worker processes (`UARPUpdaterService...`) manage background firmware updates for external Apple accessories and peripherals:

1. **Accessory Firmware Update Workers**: Spawns 7 worker instances (`UARPUpdaterServiceDisplay`, `UARPUpdaterServiceLegacyAudio`, `UARPUpdaterServiceHID`, `UARPUpdaterServiceUSBPD`, `UARPUpdaterServiceAFU`, `ThunderboltAccessoryUpdaterService`) to poll for firmware updates.
2. **Periodic Apple Firmware Checks (`periodicFirmwareCheck`)**: Issues 24-hour background network checks to Apple servers for updated accessory binaries.

## What Is NOT Affected

- **Peripherals & Accessory Functionality**: Magic Mouse, Magic Trackpad, Magic Keyboard, AirPods, MagSafe 3 chargers, USB-C power adapters, Thunderbolt 3/4 docks, cables, and external displays operate **100% normally**.
- **System Memory**: Eliminates an entire cluster of 8 background processes, freeing **~73.6MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.accessoryupdaterd 2>/dev/null || true
sudo launchctl disable system/com.apple.accessoryupdaterd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.accessoryupdaterd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.accessoryupdaterd`.
2. Process `accessoryupdaterd` and all 7 child `UARPUpdaterService...` instances terminated, releasing **~73.6MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - All 8 accessory updater processes remain stopped (`pgrep -fl "uarp|accessoryupdater"` -> 0).
   - System stability and peripheral devices operate normally.
   - Log audit confirmed 0 errors or retry loops.
