# NetworkExtension Framework Helper — nehelper

## Basics

- **Main label:** `system/com.apple.nehelper`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.nehelper.plist`
- **Binary:** `/usr/libexec/nehelper`
- **Domain:** `system`
- **Category:** `networking_core_extensions`
- **Risk:** `3` (Critical Networking Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`nehelper` (NetworkExtension Helper Daemon) is the core system helper for Apple's `NetworkExtension.framework`:

1. **VPN Tunnel Management**: Handles virtual network interface creation (`utun0`, `utun1`), routing table modifications, and certificate binding for all VPN protocols (WireGuard, OpenVPN, Tailscale, IPsec, IKEv2, Outline, Cisco AnyConnect).
2. **Network Filter & Firewall Entitlements**: Manages privileged XPC endpoints (`com.apple.networkd_privileged`) for third-party macOS firewalls and content filters (LuLu, Little Snitch, AdGuard).
3. **Network Extension Preference Monitoring**: Watches `/Library/Preferences/com.apple.networkextension.plist` for active network extension configuration changes.

## Why It Must Remain Enabled

- Disabling `nehelper` **completely breaks all VPN connections** (WireGuard, OpenVPN, Tailscale, etc.) and local network filter/firewall extensions on macOS.
- Required on developer machines for secure remote server connectivity and VPN access.

## Status

**KEPT ENABLED AND PROTECTED.**
