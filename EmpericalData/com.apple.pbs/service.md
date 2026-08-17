# Pasteboard & Application Contextual Services Server — pbs

## Basics

- **Main label:** `gui/<uid>/com.apple.pbs`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.pbs.plist`
- **Binary:** `/System/Library/CoreServices/pbs`
- **Domain:** `gui/<uid>`
- **Category:** `ui_pasteboard_services`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`pbs` (Pasteboard Server Daemon) is Apple's global System Pasteboard (`NSPasteboard`) and Application Contextual Services daemon:

1. **Global Copy & Paste Engine (`NSPasteboard`)**: Manages data type registration and inter-process data transfer for all Copy (`Cmd+C`), Cut (`Cmd+X`), and Paste (`Cmd+V`) operations across all macOS applications (text, code, images, files, formatted data).
2. **Application Services Menu Provider (`com.apple.pbs.fetch_services`)**: Scans `~/Library/Services/` and `/Library/Services/` to render contextual action commands under *App Name -> Services*.

## Why It Must Remain Enabled

- Disabling `pbs` **completely breaks system Copy & Paste functionality across macOS**: Users lose all ability to copy or paste text, code, or files in VSCode, Terminal, web browsers, and IDEs (`Cmd+C`/`Cmd+V` fails).
- Explicitly protected in `AGENTS.md` core UI guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
