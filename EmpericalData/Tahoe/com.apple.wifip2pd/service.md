# Wi-Fi Peer-to-Peer & AirDrop AWDL — wifip2pd / WiFiAgent

## Basics

- **Main labels:** `system/com.apple.wifip2pd`, `gui/<uid>/com.apple.WiFiAgent`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.wifip2pd.plist`, `/System/Library/LaunchAgents/com.apple.WiFiAgent.plist`
- **Processes:** `wifip2pd`, `WiFiAgent`
- **Domains:** `system`, `gui/<uid>`
- **Category:** `networking_p2p_airdrop`
- **Risk:** `2`
- **Verdict:** `disable for coding profile`

## What It Does

1. **`com.apple.wifip2pd` (`wifip2pd`)**:
   - Apple Wireless Direct Link (AWDL) and Wi-Fi Direct peer-to-peer daemon.
   - Manages direct device-to-device Wi-Fi connections for AirDrop, wireless Sidecar (iPad second display), wireless Continuity Camera, and direct P2P AirPlay.
   - When active, `wifip2pd` generates ~39,000 log errors per hour due to a built-in macOS LaunchServices audit token verification bug (`Failed to create LSBundleRecord from Audit Token: Code=-50`).

2. **`com.apple.WiFiAgent` (`WiFiAgent`)**:
   - GUI notifications and prompt manager for Wi-Fi join requests, network password prompts, and Cloud Keychain Wi-Fi password syncing.

3. **What is NOT affected**:
   - **Standard Wi-Fi Internet**: Managed by `airportd` (`/usr/libexec/airportd`) and `com.apple.net.wifi`. Remains 100% functional.
   - **LocalSend**: Operates over standard local LAN IP sockets (TCP/UDP port 53317) via `mDNSResponder` and continues working normally.
   - **Bluetooth**: Standard Bluetooth peripherals (mouse, keyboard, headphones) operate via `bluetoothd`.

## Rescue & Rollback Script

Rollback script created on Target Mac Desktop (`/Users/codex/Desktop/rollback-wifi.sh`) and rescue directory (`/Users/Shared/macos-tweak-rescue/rollback-wifi.sh`):

```bash
#!/usr/bin/env bash
# Rollback script for WiFiAgent and wifip2pd
set -u
uid=$(id -u)
echo "=== Rolling back WiFiAgent and wifip2pd ==="
launchctl enable "gui/$uid/com.apple.WiFiAgent" 2>/dev/null || true
sudo launchctl enable system/com.apple.wifip2pd 2>/dev/null || true
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.wifip2pd.plist 2>/dev/null || true
echo "WiFi services re-enabled. Rebooting system now..."
sudo shutdown -r now
```

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.WiFiAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.WiFiAgent"
sudo launchctl bootout system/com.apple.wifip2pd 2>/dev/null || true
sudo launchctl disable system/com.apple.wifip2pd
```

## Rollback

```bash
/Users/codex/Desktop/rollback-wifi.sh
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `rollback-wifi.sh` created on Desktop and verified executable.
2. Immediate pre-reboot check confirmed Wi-Fi internet (`en0` default route, DNS `192.168.1.1`, SSH) remained 100% active.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. **Log Storm Elimination**:
   - `wifip2pd` log error storm dropped from **~39,000 errors/hour** down to **0**.
   - Freed **~67.5MB RSS RAM** (47.1MB from `WiFiAgent` + 20.4MB from `wifip2pd`).
   - Standard Wi-Fi Internet access, LocalSend LAN file transfers, and SSH remain 100% operational.
