# Core App Extension Subsystem Daemon — PluginKit pkd

## Basics

- **Main label:** `gui/<uid>/com.apple.pluginkit.pkd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.pluginkit.pkd.plist`
- **Binary:** `/usr/libexec/pkd`
- **Domain:** `gui/<uid>`
- **Category:** `core_macos_app_extensions_pluginkit`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`pkd` (PluginKit Daemon) is Apple's primary per-user app extension and plugin discovery framework daemon:

1. **App Extension Discovery & Life-Cycle (`com.apple.pluginkit.pkd`)**: Registers, validates, and discovers all macOS App Extensions (`.appex`), including Finder sync extensions, QuickLook thumbnail plugins, Share menu extensions, and browser extensions.
2. **`PluginKit.framework` Engine**: Serves XPC requests for `PKPluginManager` across all user applications.

## Why It Must Remain Enabled

- Disabling `pkd` **completely breaks all macOS App Extensions**: Finder file integration, QuickLook previews, browser plugins, and share menu extensions fail system-wide.
- Explicitly protected in `AGENTS.md` core infrastructure guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
