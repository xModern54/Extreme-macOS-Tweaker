# com.apple.endpointsecurity.endpointsecurityd

## Basics

- **Process names:** `endpointsecurityd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.endpointsecurity.endpointsecurityd.plist`
- **Binary:** `/usr/libexec/endpointsecurityd`
- **Category:** `security_endpoint_system_extensions`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System Endpoint Security & Security System Extensions Daemon (`endpointsecurityd` / `EndpointSecurity.framework`).
Interfaces with XNU kernel Endpoint Security subsystem (`/dev/endpointsecurity`).
Responsible for:
1. **System Extensions Event Broker**: Provides real-time kernel event interception (process execution, fork, open, unlink, socket bind, mount) for:
   - Application Firewalls & Network Monitors (Little Snitch, LuLu, Radio Silence).
   - System security utilities & audit tools (Objective-See tools, ProcessMonitor, FileMonitor).
   - Antivirus & Enterprise EDR clients (CrowdStrike, SentinelOne, Microsoft Defender).
2. **System Extension Authorization Pipeline**: Authorizes or denies process execution events based on security extension policies.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `endpointsecurityd` **completely breaks third-party network firewalls (Little Snitch, LuLu) and security System Extensions**, causing them to crash or indefinitely block application execution.

Resource footprint:
~2.1 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical infrastructure for any installed firewall, developer monitoring utility, or security system extension.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Security System Extensions & Firewalls Subsystem)**.
