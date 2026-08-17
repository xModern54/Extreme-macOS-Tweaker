# Auto-Brightness, True Tone & Display Backlight Service — corebrightnessd

## Basics

- **Main label:** `system/com.apple.corebrightnessd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.corebrightnessd.plist`
- **Binary:** `/usr/libexec/corebrightnessd`
- **Domain:** `system`
- **Category:** `hardware_display_brightness_ambient_nightshift`
- **Risk:** `4` (Breaks hardware display backlight adjustments)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`corebrightnessd` (CoreBrightness Daemon) is Apple's display brightness engine:

1. **Display Backlight Control (`com.apple.backlightd`)**: Controls display hardware backlight brightness levels via keys F1/F2 and Control Center slider on Apple Silicon Macs.
2. **Ambient Light Sensor & True Tone**: Adjusts auto-brightness, True Tone, Night Shift, and keyboard auto-backlight.

## Why It Must Remain Enabled

- **CRITICAL**: Disabling `corebrightnessd` **completely breaks ALL display brightness adjustments** (manual F1/F2 keys, Control Center brightness slider, and auto-brightness fail to change screen brightness on Apple Silicon Macs).

## Rollback Command

```bash
sudo launchctl enable system/com.apple.corebrightnessd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.corebrightnessd.plist
sudo shutdown -r now
```

## Status

**KEPT ENABLED AND PROTECTED.**
