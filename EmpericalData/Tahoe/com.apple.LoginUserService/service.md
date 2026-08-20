# Login User Identity & Session Authentication XPC Service — LoginUserService

## Basics

- **Main label:** `com.apple.LoginUserService`
- **Plist path:** `/System/Library/PrivateFrameworks/login.framework/Versions/A/XPCServices/LoginUserService.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/login.framework/Versions/A/XPCServices/LoginUserService.xpc/Contents/MacOS/LoginUserService`
- **Domain:** `pid/<pid> [ControlCenter/loginwindow]`
- **Category:** `ui_required_loginwindow`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`LoginUserService` (Login Framework User Identity Service) is Apple's login session and lock screen user authentication XPC service (`login.framework` / `loginwindow`):

1. **User Identity & Password Authentication (`opendirectoryd.identity`)**: Bridges user account authentication (`codex`), password validation, and user avatar state between `loginwindow`, `opendirectoryd`, and `ControlCenter` during login and lock screen events (`Cmd+Ctrl+Q`).
2. **Lock Screen & Fast User Switching**: Manages UI state transitions during system lock screen and user session switching.

## Why It Must Remain Enabled

- Disabling `LoginUserService` **completely breaks user authentication and lock screen unlocking in macOS**: Users become unable to unlock screen sessions or log into macOS post-boot.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
