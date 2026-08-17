# Kernel Seatbelt Sandbox Enforcement & Event Helper Daemon — sandboxd

## Basics

- **Main label:** `system/com.apple.sandboxd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.sandboxd.plist`
- **Binary:** `/usr/libexec/sandboxd`
- **Domain:** `system`
- **Category:** `auth_security_app_sandbox`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`sandboxd` (Sandbox Helper Daemon) is Apple's kernel Seatbelt sandbox enforcement and event helper daemon:

1. **Kernel Seatbelt Host Special Port Handler (`HostSpecialPort: 14`)**: Registers directly into XNU Kernel Special Port 14 (`seatbelt`), providing Mandatory Access Control (MAC) sandbox policy enforcement for isolated application processes.
2. **Sandbox Deny Event Processor & TCC Sync**: Handles out-of-bounds access violations (`Sandbox Deny`) and synchronizes process profile constraints when TCC privacy permissions change (`com.apple.tcc.access.changed`).

## Why It Must Remain Enabled

- Disabling `sandboxd` **completely breaks kernel Seatbelt sandbox enforcement and application execution across macOS**: Sandboxed apps fail to initialize process constraints and crash on launch.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
