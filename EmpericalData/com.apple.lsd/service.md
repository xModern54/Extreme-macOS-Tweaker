# Core LaunchServices Application & File Association Daemon — lsd

## Basics

- **Main labels:** `system/com.apple.lsd`, `gui/<uid>/com.apple.lsd`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.lsd.plist`, `/System/Library/LaunchAgents/com.apple.lsd.plist`
- **Binary:** `/usr/libexec/lsd`
- **Domain:** `system`, `gui/<uid>`
- **Category:** `core_macos_launchservices_app_bindings`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`lsd` (LaunchServices Daemon) is Apple's primary per-system and per-user application binding and file association engine:

1. **File Type & URL Scheme Binding Database**: Maps file extensions (`.py`, `.js`, `.pdf`), MIME types, and URL protocols (`https://`, `vscode://`, `docker://`) to registered applications.
2. **`LSOpenApplication` & `open` CLI Processing**: Resolves and dispatches application launches whenever files are opened via Finder double-clicks, web links, or the terminal `open` command.

## Why It Must Remain Enabled

- Disabling `lsd` **completely breaks all application and file opening capabilities**: `open` command, Finder file launches, and URL link dispatching collapse with `LaunchServices Error -10810`.
- Explicitly listed as a protected core component in `AGENTS.md`.

## Status

**KEPT ENABLED AND PROTECTED.**
