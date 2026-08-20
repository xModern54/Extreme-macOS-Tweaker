# Universal Access Authorization Warning Dialog Agent — `com.apple.universalaccessAuthWarn`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Universal Access Authorization Prompts (macOS 27)             |
| Category      | `accessibility` / `system_dialogs`                           |
| Risk Level    | **2** — Suppresses Accessibility authorization warning dialogs|
| Profile       | **safe to disable on power-user target with pre-set TCC**     |
| Verdict       | **disable** (frees ~31 MB RAM)                               |

- **Main label:** `gui/<uid>/com.apple.universalaccessAuthWarn`
- **Plist:** `/System/Library/LaunchAgents/com.apple.universalaccessAuthWarn.plist`
- **Binary:** `/System/Library/PrivateFrameworks/UniversalAccess.framework/Versions/A/Resources/universalAccessAuthWarn.app/Contents/MacOS/universalAccessAuthWarn`
- **Domain:** `gui/<uid>`
- **Mach Services:** `com.apple.universalaccessAuthWarn`
- **Properties:** `RunAtLoad = false`, `ProcessType = App`, `LimitLoadToSessionType = [Aqua]`

## What It Does (За что отвечает)

`com.apple.universalaccessAuthWarn` is the specialized authorization dialog agent for Accessibility and Input Monitoring in macOS.

1. **Accessibility Consent Prompts:** Displays system warning sheets when newly launched third-party apps attempt to use Accessibility APIs, UI element inspection, or simulated input.
2. **Event Tap Detection:** Warns users when background utilities install global event taps to intercept keyboard or mouse events.

When disabled, applications that already have Accessibility permissions granted in *System Settings > Privacy & Security > Accessibility* continue to function normally. New applications will not display the prompt modal.

## Observed Cost (macOS 27 Golden Gate Baseline)

| Process | Domain | RSS RAM | CPU Idle |
|---|---|---|---|
| `universalAccessAuthWarn` (`UniversalAccess.framework`) | `gui/<uid>` | **~30.8 MB** | 0.0% |

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.universalaccessAuthWarn" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.universalaccessAuthWarn"
killall universalAccessAuthWarn 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.universalaccessAuthWarn"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.universalaccessAuthWarn.plist
```

## Test Result

**Date:** 2026-08-20  
**Target:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)

1. Pre-disable: `universalAccessAuthWarn` was resident at **30,832 KB RSS** after being invoked by background tools.
2. Executed `launchctl bootout` and `launchctl disable`.
3. Process terminated immediately without hanging, saving **~31 MB RAM**.
4. Existing tools with Accessibility access remained operational.
