# Service Management & Privileged Helper Installation Daemon — smd

## Basics

- **Main label:** `system/com.apple.xpc.smd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.xpc.smd.plist`
- **Binary:** `/usr/libexec/smd`
- **Domain:** `system`
- **Category:** `system_service_management_smd`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`smd` (Service Management Daemon) is Apple's Service Management framework daemon (`ServiceManagement.framework`):

1. **Privileged Helper Installation Engine (`SMJobBless`)**: Validates code-signing signatures, prompts for Administrator credentials, and installs privileged background system daemons into `/Library/LaunchDaemons/` for developer tools and applications (Docker, OrbStack, Wireshark, VPN clients, virtualization utilities).
2. **LaunchDaemons Watcher (`/Library/LaunchDaemons/`)**: Monitors `/Library/LaunchDaemons/` for newly installed or updated third-party daemon configuration files.

## Why It Must Remain Enabled

- Disabling `smd` (`com.apple.xpc.smd`) **completely breaks installation and updates of developer tools and privileged daemons across macOS**: Docker, OrbStack, VPN clients, and system utilities fail with `SMJobBless` authorization errors.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
