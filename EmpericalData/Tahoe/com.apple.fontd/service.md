# Core System Font Registration & Resolution Daemon — fontd (xtyped)

## Basics

- **Main label:** `gui/<uid>/com.apple.xtyped` (formerly `com.apple.fontd.useragent`)
- **Plist path:** `/System/Library/LaunchAgents/com.apple.fontd.useragent.plist`
- **Binary:** `/System/Library/Frameworks/ApplicationServices.framework/Frameworks/ATS.framework/Support/fontd`
- **Domain:** `gui/<uid>`
- **Category:** `system_font_management_core`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`fontd` (Font Daemon / `xtyped`) is Apple's primary system font registration and CoreText glyph resolution daemon:

1. **System Font Resolution Engine (`com.apple.fonts`)**: Resolves requested font family names (SF Pro, Inter, Menlo, Fira Code) to physical font files in `/System/Library/Fonts/` and `/Library/Fonts/`, delivering character glyph metrics to `CoreText`.
2. **ATS Bridge Provider (`com.apple.fonts.atsbridge`)**: Maintains legacy Apple Type Services font bridge compatibility for macOS applications.

## Why It Must Remain Enabled

- Disabling `fontd` (`com.apple.xtyped`) **completely breaks all text rendering across macOS**: All text in System UI, menus, Terminal, VSCode, web browsers, and apps renders as empty blank squares or crashes application window threads.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
