# AppKit Remote Views XPC Service — ViewBridgeAuxiliary

## Basics

- **Main label:** Embedded AppKit XPC bundle (`com.apple.ViewBridgeAuxiliary`)
- **Binary path:** `/System/Library/PrivateFrameworks/ViewBridge.framework/Versions/A/XPCServices/ViewBridgeAuxiliary.xpc/Contents/MacOS/ViewBridgeAuxiliary`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `ui_viewbridge_remote_views`
- **Risk:** `4` (Critical System UI Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`ViewBridgeAuxiliary` is Apple's primary out-of-process AppKit Remote View hosting XPC service:

1. **Out-of-Process Remote View Rendering (`NSViewBridge`)**: Renders isolated system overlays and modal panels—such as **`NSOpenPanel` / `NSSavePanel` file pickers, Touch ID authorization dialogs, Gatekeeper prompt overlays, and security input fields**—outside application process memory spaces.
2. **Sandbox UI Isolation Security**: Prevents sandboxed applications from capturing input events (keystrokes, mouse clicks) inside privileged system security dialogs.

## Why It Must Remain Enabled

- Disabling `ViewBridgeAuxiliary` **completely breaks all macOS system modal file dialogs (`NSOpenPanel` / `NSSavePanel`) and security prompt overlays**, causing applications to freeze when opening or saving files.
- Explicitly protected in `AGENTS.md` core UI guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
