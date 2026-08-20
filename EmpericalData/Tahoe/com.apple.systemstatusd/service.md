# System Status Activity Indicators Daemon — systemstatusd

## Basics

- **Main label:** `system/com.apple.systemstatusd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.systemstatusd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/SystemStatusServer.framework/Support/systemstatusd`
- **Domain:** `system`
- **Category:** `ui_system_status_indicators`
- **Risk:** `2-3` (Conditional UI Privacy Indicator Service)
- **Verdict:** `RESTORED / KEPT ENABLED FOR PRIVACY & MEDIA INDICATOR DOTS`

## What It Does

`systemstatusd` (System Status Server Daemon) coordinates system status indicators across macOS:

1. **Top Menu Bar Activity Indicators**: Renders orange microphone activity dots (🟠), green camera activity dots (🟢), screen recording status, and location service arrows in the top menu bar.
2. **Control Center Activity Attribution**: Publishes active media device usage attribution (`com.apple.systemstatus.activityattribution`) to Control Center.

## Why It Was Restored

- Disabling `systemstatusd` removes live privacy activity indicators (microphone/camera/screen-record status dots).
- **User Verdict**: Restored per user preference. Sacrificing core privacy/security UI indicators for a trivial ~20.5MB RAM saving is not recommended.

## Status

**KEPT ENABLED AND RESTORED.**
