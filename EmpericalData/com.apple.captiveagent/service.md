# Wi-Fi Captive Portal Detection — captiveagent

## Basics

- **Main label:** `system/com.apple.captiveagent`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.captiveagent.plist`
- **Binary:** `/usr/libexec/captiveagent`
- **Domain:** `system`
- **Category:** `networking_captive_portal`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`captiveagent` (Captive Network Portal Agent) is Apple's background detector for public Wi-Fi web authentication portals (airports, hotels, subways, cafes):

1. **Hotspot Probe Pings**: Issues HTTP requests to `captive.apple.com` upon Wi-Fi network association to detect redirect portals.
2. **WebSheet Triggering**: Triggers the `WebSheet.app` popup interface to present web authentication login forms.

## What Is NOT Affected

- **Standard Wi-Fi & Ethernet Networking**: Home Wi-Fi, office WPA2/WPA3 Personal and Enterprise networks, iPhone Personal Hotspots, Bluetooth tethering, and wired Ethernet operate **100% normally**.
- **Manual Web Auth Entry**: Public Wi-Fi captive portals remain accessible by navigating to any HTTP URL in a standard browser.
- **Background Traffic**: Eliminates periodic `captive.apple.com` probes.

## Disable

```bash
sudo launchctl bootout system/com.apple.captiveagent 2>/dev/null || true
sudo launchctl disable system/com.apple.captiveagent
```

## Rollback

```bash
sudo launchctl enable system/com.apple.captiveagent
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.captiveagent`.
2. Process `captiveagent` terminated, releasing **~13.1MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `captiveagent` process remains stopped.
   - Standard Wi-Fi and network routing operate normally.
   - Log audit confirmed 0 errors or retry loops.
