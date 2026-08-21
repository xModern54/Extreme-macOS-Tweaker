# com.apple.wifi.WiFiAgent

## Basics

- **Process names:** `WiFiAgent`
- **Domain:** `gui/<uid>`
- **Plist:** `/System/Library/CleanSweep/LaunchAgents/com.apple.wifi.WiFiAgent.plist` (or `/System/Library/LaunchAgents/com.apple.wifi.WiFiAgent.plist`)
- **Binary:** `/System/Library/CoreServices/WiFiAgent.app/Contents/MacOS/WiFiAgent`
- **Category:** `ui_wifi_menubar_status_and_prompts`
- **Risk:** `2` (Conditional UI tweak)
- **Verdict:** `disable-if-icon-hidden-or-ethernet`

## Notes

What it does:
User GUI Agent for Wi-Fi Menu Bar Icon, Password Prompts & Hotspot Banners (`WiFiAgent.app`).
Responsible for:
1. **Top Menu Bar Status Icon State**: Feeds live connection state, signal strength bars, and visual indicators to the top menu bar Wi-Fi extra (`ControlCenter` / `MenuBarAgent`).
2. **Wi-Fi Password Dialogs**: Displays "Enter password for Wi-Fi network" input dialogs.
3. **Captive Portal Popups**: Launches captive login web sheets on public networks.
4. **Hotspot & Sharing Prompts**: Displays notifications when an iPhone Personal Hotspot is detected or nearby Apple IDs want to share Wi-Fi credentials.

What is NOT affected:
- **Core Wi-Fi Connectivity & Internet**: Hardware Wi-Fi radio, scanning, WPA2/WPA3 associations, DHCP/IP routing, DNS, speed, and internet connectivity continue to operate **100% normally** through `airportd` (`/usr/libexec/airportd`) and the `AppleBCMWLAN` driver.

Observed Visual Behavior When Disabled:
- **Visual Glitch**: When `WiFiAgent` is disabled, the Wi-Fi icon in the top Menu Bar stops receiving UI state updates and appears empty / disconnected / searching, even though Wi-Fi and internet are working at full speed.
- **When Safe to Disable**:
  1. If the Wi-Fi icon is removed from the top bar (*System Settings -> Control Center -> Wi-Fi -> Don't Show in Menu Bar*).
  2. On desktop Macs connected via Ethernet (LAN cable) or fixed connections.
  - Disabling saves **~40–47 MB RAM**.

Disable:
```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.wifi.WiFiAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.wifi.WiFiAgent"
killall WiFiAgent 2>/dev/null || true
```

Rollback:
```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.wifi.WiFiAgent"
launchctl bootstrap "gui/$uid" /System/Library/CleanSweep/LaunchAgents/com.apple.wifi.WiFiAgent.plist 2>/dev/null || true
launchctl kickstart -k "gui/$uid/com.apple.wifi.WiFiAgent"
killall ControlCenter
```

Verdict:
**SAFE TO DISABLE IF ICON IS HIDDEN FROM MENU BAR OR ON ETHERNET (Risk 2)**.
Saves ~40–47 MB RAM; does not affect network traffic or internet speed.
