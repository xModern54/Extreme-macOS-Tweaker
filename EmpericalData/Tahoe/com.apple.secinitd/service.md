# App Sandbox Initialization & Container Entitlement Daemon — secinitd

## Basics

- **Main label:** `gui/<uid>/com.apple.secinitd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.secinitd.plist`
- **Binary:** `/usr/libexec/secinitd`
- **Domain:** `gui/<uid>`
- **Category:** `auth_security_app_sandbox`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`secinitd` (Security Initialization Daemon) is Apple's App Sandbox and container entitlement initialization daemon:

1. **App Sandbox Container Initializer (`~/Library/Containers/`)**: Reads application code-signing entitlements on launch and initializes isolated container directory structures for all sandboxed macOS applications (Xcode, Safari, Terminal, VSCode, Telegram, Slack, Preview, Electron apps).
2. **Seatbelt Sandbox Enforcement**: Applies Mandatory Access Control (MAC) sandbox rules restricting application filesystem access.

## Why It Must Remain Enabled

- Disabling `secinitd` **completely breaks execution of all sandboxed applications across macOS**: Apps crash immediately on launch with container initialization failures.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
