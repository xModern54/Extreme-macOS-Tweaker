# Wi-Fi User Notifications & Auto-Hotspot Agent — com.apple.wifi.WiFiAgent

## Basics

- **Main label:** `gui/<uid>/com.apple.wifi.WiFiAgent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.wifi.WiFiAgent.plist`
- **Binary:** `/System/Library/CoreServices/WiFiAgent.app/Contents/MacOS/WiFiAgent`
- **Domain:** `gui/<uid>`
- **Category:** `ui_wifi_status_menu_notifications`
- **Risk:** `2` (Conditional for users who rely on top Menu Bar Wi-Fi status icon rendering)
- **Verdict:** `disable for coding profile with top Menu Bar icon hidden`

## What It Does

`WiFiAgent` (Wi-Fi User Agent) manages user-facing Wi-Fi notification overlays, open network join popups, Personal Hotspot prompts, Wi-Fi password sharing dialogs, and top Menu Bar status icon state updates:

1. **Top Menu Bar Wi-Fi Status Icon Renderer**: Supplies live signal strength bars and connection state updates to the Wi-Fi menu bar status icon in the top menu bar.
2. **User Open Network Join Prompts (`usernotifications.join`)**: Displays popup banners suggesting connection to newly discovered open Wi-Fi networks.
3. **Personal Hotspot Auto-Connect Prompts (`usernotifications.autohotspot`)**: Displays connection banners when an iPhone or iPad Personal Hotspot is detected nearby.
4. **Wi-Fi Password Sharing Dialogs**: Renders UI cards prompting to share saved Wi-Fi network passwords with nearby Apple ID contacts.

## What Is NOT Affected

- **Wi-Fi Hardware & Internet Connectivity**: Core Wi-Fi networking, router scanning, WPA2/WPA3 authentication, IP configuration, DNS, internet traffic, Xcode, Terminal, Git, Docker, SSH, and sound operate **100% normally** via system daemon `airportd` (`/usr/libexec/airportd`).
- **System Memory**: Eliminates persistent GUI agent, freeing **~47.5MB RSS RAM**.

## Important Menu Bar Status Behavior

> [!WARNING]
> **Menu Bar Wi-Fi Status Icon Behavior**: When `WiFiAgent` is disabled, the top Menu Bar Wi-Fi status icon stops receiving state updates and may display an inaccurate "Wi-Fi Off" or weak signal icon—even though actual Wi-Fi internet connection operates 100% fine via `airportd`.
> 
> **Recommendation**: If live Menu Bar signal bars are required, **keep `WiFiAgent` enabled**. If disabling `WiFiAgent` to save **~47.5MB RAM**, remove the Wi-Fi icon from the top menu bar (**System Settings -> Control Center -> Wi-Fi -> Don't Show in Menu Bar**) to avoid misleading status indicators.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.wifi.WiFiAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.wifi.WiFiAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.wifi.WiFiAgent"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.wifi.WiFiAgent`.
2. Process `WiFiAgent` terminated, releasing **~47.5MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `WiFiAgent` process remains stopped permanently.
   - Physical Wi-Fi connectivity, network joining, and internet access operate 100% normally via `airportd`.
   - Log audit confirmed 0 errors or retry loops.
