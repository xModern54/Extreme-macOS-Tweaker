# Apple Media Products Device Discovery — AMPDeviceDiscoveryAgent

## Basics

- **Main label:** `com.apple.AMPDeviceDiscoveryAgent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.AMPDeviceDiscoveryAgent.plist`
- **Binary:** `/System/Library/PrivateFrameworks/AMPDevices.framework/Versions/A/Support/AMPDeviceDiscoveryAgent`
- **Domain:** `gui/<uid>`
- **Category:** `media_devices_sync`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`AMPDeviceDiscoveryAgent` (Apple Media Products Device Discovery Agent) is the background service responsible for discovering physical Apple iOS/iPadOS devices over USB and Wi-Fi:

1. **Finder Sidebar Mounting**: Automatically detects connected iPhones/iPads and registers them under *"Locations"* in the Finder sidebar.
2. **Device Sync & Backup**: Triggers media library sync and local disk backups for iOS devices via Finder.

## What Is NOT Affected

- **AltStore / AltServer / Sideloadly / Xcode Compatibility**: **100% FUNCTIONAL!** Sideloading tools communicate directly via the low-level `usbmuxd` socket (`/var/run/usbmuxd`) and `MobileDevice.framework`. They do NOT rely on `AMPDeviceDiscoveryAgent` and continue detecting connected iPhones/iPads for signing and installing IPA files normally!
- **USB Battery Charging**: Connecting iPhones/iPads continues charging normally.
- **USB Personal Hotspot / Tethering**: Sharing cellular internet from iPhone via USB cable operates via `usbmuxd` and remains **100% functional**.
- **System Stability**: Wi-Fi, SSH, Git, Docker, and terminal operate without issues.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.AMPDeviceDiscoveryAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AMPDeviceDiscoveryAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.AMPDeviceDiscoveryAgent"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `launchctl bootout` and `launchctl disable` applied for `gui/502/com.apple.AMPDeviceDiscoveryAgent`.
2. Process `AMPDeviceDiscoveryAgent` terminated, releasing **~11MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Verified:
   - `AMPDeviceDiscoveryAgent` process remains stopped.
   - USB charging and network tethering remain active.
