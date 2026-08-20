# Keyboard Language Layout Switcher & HUD Server — TextInputSwitcher

## Basics

- **Main label:** `gui/<uid>/com.apple.TextInputSwitcher`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.TextInputSwitcher.plist`
- **Binary:** `/System/Library/CoreServices/TextInputSwitcher.app/Contents/MacOS/TextInputSwitcher`
- **Domain:** `gui/<uid>`
- **Category:** `ui_keyboard_input_switcher`
- **Risk:** `4` (Critical System Safety Infrastructure — Language Switching Lockout)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`TextInputSwitcher` (Text Input Switcher Server) is Apple's primary input source switcher and language HUD daemon (`HIToolbox.framework` / `Carbon.framework`):

1. **Keyboard Language Layout Switching**: Listens for language switching shortcuts (`Cmd+Space`, `Ctrl+Space`, `Caps Lock`, `Globe/Fn` key) and switches active character input sources between languages (e.g. Russian <-> English).
2. **Language HUD Menu Overlay**: Renders the floating language HUD selection menu in the center of the screen when holding down input source shortcuts.

## Why It Must Remain Enabled

- Disabling `TextInputSwitcher` **completely breaks keyboard language switching across macOS**: Shortcut keys (`Cmd+Space`, `Caps Lock`) cease changing input languages, locking the user onto a single active language layout.
- Explicitly protected in `AGENTS.md` core input guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
