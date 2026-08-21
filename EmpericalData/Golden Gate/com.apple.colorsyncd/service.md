# com.apple.colorsyncd

## Basics

- **Process names:** `colorsyncd`, `colorsync.displayservices`, `com.apple.ColorSyncXPCAgent`
- **Domain:** `system`, `gui/<uid>`
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.colorsyncd.plist`
  - `/System/Library/LaunchDaemons/com.apple.colorsync.displayservices.plist`
- **Binary:** `/usr/libexec/colorsyncd`, `/usr/libexec/colorsync.displayservices`
- **Category:** `hardware_display_color_management`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System Display Color Management, ICC Profiles & Display Calibration Subsystem (`ColorSync.framework` / `CoreGraphics`).
Responsible for:
1. **Display Hardware Color Calibration (Display P3 / sRGB / HDR)**: Applies factory ICC calibration profiles for Liquid Retina XDR / P3 displays and external monitors, ensuring color accuracy across video, images, web browsers, and UI rendering.
2. **Night Shift & True Tone Hardware Integration**: Coordinates dynamic color temperature (Night Shift) and ambient light white balance adjustments (True Tone / `corebrightnessd`).
3. **Color Profile Conversions**: High-speed color space transformations for Metal, Quartz, and ImageIO.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `ColorSync` **corrupts display color rendering across macOS**: Displays lose hardware ICC calibration, producing distorted gamma, washed out or oversaturated colors, and broken Night Shift / True Tone hardware controls.

Resource footprint:
3 instances consume ~14.6 MB RAM total, 0.0% CPU.

Needed for coding / system:
Yes. Critical core graphics display hardware management.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Display Hardware Color Calibration Subsystem)**.
