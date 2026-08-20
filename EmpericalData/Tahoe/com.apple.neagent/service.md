# Network Extension & VPN Subsystem — neagent & nehelper

## Basics

- **Main labels:** `gui/<uid>/com.apple.neagent`, `system/com.apple.nehelper`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.neagent.plist`, `/System/Library/LaunchDaemons/com.apple.nehelper.plist`
- **Binaries:** `/usr/libexec/neagent`, `/usr/libexec/nehelper`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `networking_vpn_network_extension`
- **Risk:** `4` (Critical for VPN users) / `2` (Conditional for non-VPN profiles)
- **Verdict:** `PROTECTED for VPN users / CONDITIONAL for non-VPN profiles`

## What It Does

`neagent` and `nehelper` manage Apple's Network Extension framework (`NetworkExtension.framework`):

1. **VPN Tunnel Engine (`utun` Interfaces)**: Manages network virtual interface creation (`utun`), packet routing, and encryption for **WireGuard, OpenVPN, Tailscale, Cloudflare WARP, Cisco AnyConnect, Tunnelblick, ProtonVPN, and native IKEv2/IPSec VPNs**.
2. **Network Content Filters & Firewalls**: Coordinates App Proxy and packet content filter extensions for network firewalls (Little Snitch, LuLu).

## Why It Must Remain Enabled for Developers

- Disabling `neagent` or `nehelper` **completely breaks all VPN connections, WireGuard tunnels, Tailscale mesh networking, and custom network extensions across macOS**.
- Must remain enabled for any developer workflow relying on VPNs or remote server access.

## Status

**KEPT ENABLED AND PROTECTED FOR VPN WORKFLOWS.**
