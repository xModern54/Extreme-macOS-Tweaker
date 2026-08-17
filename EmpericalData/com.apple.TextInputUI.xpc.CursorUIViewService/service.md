# Text Input Cursor Language Indicator Service — CursorUIViewService

## Basics

- **Main label:** `com.apple.TextInputUI.xpc.CursorUIViewService`
- **Plist path:** Embedded framework XPC (`/System/Library/PrivateFrameworks/TextInputUIMacHelper.framework/Versions/A/XPCServices/CursorUIViewService.xpc`)
- **Binary:** `/System/Library/PrivateFrameworks/TextInputUIMacHelper.framework/Versions/A/XPCServices/CursorUIViewService.xpc/Contents/MacOS/CursorUIViewService`
- **Domain:** `user/<uid>`, `gui/<uid>`, `system`
- **Category:** `ui_text_input_cursor_indicator`
- **Risk:** `2` (Conditional for single-language keyboard setups)
- **Verdict:** `CONDITIONAL — disable ONLY if single keyboard language layout is used`

## What It Does

`CursorUIViewService` is Apple's text input UI cursor floating badge renderer and `HIToolbox` binding listener:

1. **Floating Language Indicator Pill Badge (RU/EN)**: Renders a temporary blue/green capsule pill badge showing the active input language (`RU` or `EN`) adjacent to the text insertion caret when switching keyboard input sources.
2. **HIToolbox Input Key Listener Connection**: Interacts with `TextInputMenuAgent` and `TextInputSwitcher` to process physical keyboard language switching events (Caps Lock / Fn / Cmd+Space).

## Conditional Logic for Optimization Profiles

- **Multilingual Setup (RU + EN)**: **KEEP ENABLED**. Disabling `CursorUIViewService` causes `TextInputMenuAgent` and `HIToolbox` to lose their physical keyboard shortcut event tap for layout switching.
- **Single-Language Setup (English-only)**: **SAFE TO DISABLE**. For single-language Macs without layout switching, disabling `CursorUIViewService` frees **~32.3MB RSS RAM** without any drawbacks.

## Disable (Single-Language Profile)

```bash
uid=$(id -u)
launchctl bootout "user/$uid/com.apple.TextInputUI.xpc.CursorUIViewService" 2>/dev/null || true
launchctl disable "user/$uid/com.apple.TextInputUI.xpc.CursorUIViewService"
launchctl bootout "gui/$uid/com.apple.TextInputUI.xpc.CursorUIViewService" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.TextInputUI.xpc.CursorUIViewService"
sudo launchctl bootout system/com.apple.TextInputUI.xpc.CursorUIViewService 2>/dev/null || true
sudo launchctl disable system/com.apple.TextInputUI.xpc.CursorUIViewService
sudo killall CursorUIViewService 2>/dev/null || true
```

## Rollback / Restore Command

```bash
uid=$(id -u)
launchctl enable "user/$uid/com.apple.TextInputUI.xpc.CursorUIViewService"
launchctl enable "gui/$uid/com.apple.TextInputUI.xpc.CursorUIViewService"
sudo launchctl enable system/com.apple.TextInputUI.xpc.CursorUIViewService
killall TextInputMenuAgent TextInputSwitcher 2>/dev/null || true
```

## Status

**DOCUMENTED AS CONDITIONAL TWEAK (RISK LEVEL 2).**
