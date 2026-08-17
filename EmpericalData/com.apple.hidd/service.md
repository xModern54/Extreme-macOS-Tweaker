# Human Interface Device Input Engine Daemon — hidd

## Basics

- **Main label:** `system/com.apple.hidd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.hidd.plist`
- **Binary:** `/usr/libexec/hidd`
- **Domain:** `system`
- **Category:** `ui_required_hid_input`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`hidd` (Human Interface Device Daemon) is Apple's primary hardware input event processing daemon (`IOHIDFamily` / `IOKit` / `WindowServer`):

1. **Keyboard, Trackpad & Mouse Hardware Input Processor**: Receives low-level hardware input interrupts from MacBook built-in keyboards, trackpads, USB/Bluetooth mice, and graphics tablets, translating raw HID events into window events for `WindowServer` and all applications.
2. **Multitouch Gestures & Acceleration**: Manages cursor acceleration, trackpad multitouch scrolling, and system power button event triggers.

## Why It Must Remain Enabled

- Disabling `hidd` **instantly kills all keyboard, mouse, trackpad, and button input across macOS**: Users lose all capability to click, swipe, or type any keystrokes.
- Explicitly protected in `AGENTS.md` core input infrastructure guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
