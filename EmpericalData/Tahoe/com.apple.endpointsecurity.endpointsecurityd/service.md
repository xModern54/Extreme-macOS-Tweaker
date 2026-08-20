# System Endpoint Security & Antivirus/Firewall Subsystem Daemon — endpointsecurityd

## Basics

- **Main label:** `system/com.apple.endpointsecurity.endpointsecurityd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.endpointsecurity.endpointsecurityd.plist`
- **Binary:** `/usr/libexec/endpointsecurityd`
- **Domain:** `system`
- **Category:** `auth_security_endpoint_security`
- **Risk:** `4` (Critical System Security Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`endpointsecurityd` (Endpoint Security Daemon) is Apple's primary Endpoint Security framework daemon (`EndpointSecurity.framework`):

1. **System Extensions Security API Provider (`com.apple.endpointsecurity.system-extensions`)**: Provides XNU kernel C-API event interception for third-party security, process monitoring, and firewall tools:
   - Application Firewalls & Network Monitors (Little Snitch, LuLu)
   - Antivirus & Enterprise EDR clients (CrowdStrike, SentinelOne, Microsoft Defender, Objective-See security tools)
   - Real-time kernel event auditing (process execution, fork, file creation, socket bind).
2. **System Extension Activator (`/Library/SystemExtensions/EndpointSecurity/.launch_esd`)**: Dynamically engages kernel event listeners upon detecting registered security System Extensions.

## Why It Must Remain Enabled

- Disabling `endpointsecurityd` **completely breaks third-party security clients, System Extensions, and firewalls (Little Snitch, LuLu, security tools)**, causing them to crash or block application execution.
- Explicitly protected in `AGENTS.md` core security guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
