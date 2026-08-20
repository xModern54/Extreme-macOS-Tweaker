# System Color Management & Display Profile Calibration Subsystem — ColorSync

## Basics

- **Main labels:** `system/com.apple.colorsyncd`, `system/com.apple.colorsync.displayservices`, `gui/<uid>/com.apple.colorsync.useragent`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.colorsyncd.plist`, `/System/Library/LaunchDaemons/com.apple.colorsync.displayservices.plist`, `/System/Library/LaunchAgents/com.apple.colorsync.useragent.plist`
- **Binaries:** `/usr/libexec/colorsyncd`, `/usr/libexec/colorsync.displayservices`
- **Domain:** `system`, `gui/<uid>`
- **Category:** `ui_display_color_management`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`ColorSync` (`colorsyncd` / `colorsync.displayservices`) is Apple's primary hardware display color management and ICC profile calibration subsystem (`ColorSync.framework` / `CoreGraphics`):

1. **Display Hardware Color Calibration (Display P3 / sRGB / HDR)**: Applies factory ICC color profile calibration matrices for Liquid Retina P3 displays and external monitors, ensuring color accuracy across video, images, web browsers, and applications.
2. **Night Shift & True Tone Hardware Adjuster**: Coordinates dynamic color temperature (Night Shift) and ambient light white balance adjustments (True Tone).

## Why It Must Remain Enabled

- Disabling `ColorSync` **corrupts display color rendering across macOS**: Displays lose hardware ICC calibration, rendering distorted gamma, oversaturated colors, and broken Night Shift / True Tone hardware integration.
- Explicitly protected in `AGENTS.md` core UI guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
