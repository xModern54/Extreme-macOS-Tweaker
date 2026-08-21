# com.apple.deviceconfigurationd / com.apple.DeviceConfigurationAgent

## Basics

- **Process names:** `deviceconfigurationd`, `DeviceConfigurationAgent`
- **Domain:** `system` (`com.apple.deviceconfigurationd`), `gui/<uid>` (`com.apple.DeviceConfigurationAgent`)
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.deviceconfigurationd.plist`
  - `/System/Library/LaunchAgents/com.apple.DeviceConfigurationAgent.plist`
- **Binary:** `/System/Library/PrivateFrameworks/DeviceConfiguration.framework/Versions/A/deviceconfigurationd`, `/System/Library/PrivateFrameworks/DeviceConfiguration.framework/Versions/A/DeviceConfigurationAgent`
- **Category:** `enterprise_mdm_declarative_management`
- **Risk:** `1`
- **Verdict:** `disable`

## Notes

What it does:
Apple Declarative Device Management (DDM) & Configuration Profile Engine (`DeviceConfiguration.framework` / `RemoteManagement.framework`).
Responsible for:
1. **Declarative Device Management (MDM / Apple Business & School Manager)**: Applies configuration policies, restrictions, and enterprise payloads from MDM servers (Jamf, Intune, Kandji, Mosyle).
2. **OpenDirectory User Record Monitoring**: Listens for user creation/deletion events and publishes `com.apple.DeviceConfiguration.system.effective-configuration-changed`.
3. Bridges with `DeviceConfigurationSubscriber.xpc` in `RemoteManagement.framework`.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~6.7 MB RAM, 0.0% CPU.

Needed for coding / personal system:
No. Personal, non-enterprise Macs without enrolled corporate MDM profiles do not use Declarative Device Management. Disabling it saves RAM and prevents background profile status checks.

Disable:
```bash
sudo launchctl bootout system/com.apple.deviceconfigurationd 2>/dev/null || true
sudo launchctl disable system/com.apple.deviceconfigurationd
launchctl bootout gui/<uid>/com.apple.DeviceConfigurationAgent 2>/dev/null || true
launchctl disable gui/<uid>/com.apple.DeviceConfigurationAgent
```

Rollback:
```bash
sudo launchctl enable system/com.apple.deviceconfigurationd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.deviceconfigurationd.plist
launchctl enable gui/<uid>/com.apple.DeviceConfigurationAgent
launchctl bootstrap gui/<uid> /System/Library/LaunchAgents/com.apple.DeviceConfigurationAgent.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely booted out and disabled. System operates 100% normally without issues.
Verdict: **SAFE TO DISABLE FOR NON-MDM PERSONAL MACS (Risk 1)**.
