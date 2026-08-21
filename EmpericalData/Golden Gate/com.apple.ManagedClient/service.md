# com.apple.ManagedClient (MCX / MDM Client Subsystem)

## Basics

- **Process names:** `ManagedClient`, `ManagedClientAgent`
- **Domain:** `system`, `gui/<uid>`
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.ManagedClient.plist`
  - `/System/Library/LaunchDaemons/com.apple.ManagedClient.startup.plist`
  - `/System/Library/LaunchDaemons/com.apple.ManagedClient.enroll.plist`
  - `/System/Library/LaunchDaemons/com.apple.ManagedClient.mechanism.plist`
  - `/System/Library/LaunchDaemons/com.apple.mdmclient.daemon.runatboot.plist`
  - `/System/Library/LaunchAgents/com.apple.ManagedClientAgent.agent.plist`
- **Binary:** `/System/Library/CoreServices/ManagedClient.app/Contents/MacOS/ManagedClient`, `/System/Library/CoreServices/ManagedClient.app/Contents/Resources/ManagedClientAgent`
- **Category:** `enterprise_mdm_managed_client`
- **Risk:** `1`
- **Verdict:** `disable`

## Notes

What it does:
Legacy & Enterprise Managed Client (MCX) and Mobile Device Management (MDM) profile engine.
Responsible for:
1. **Corporate Policy & Profile Enforcement**: Applies configuration payloads from enterprise MDM servers (Jamf, Intune, Kandji) at startup, login, and periodic background check-ins.
2. **Device Enrollment Checks**: Verifies automated device enrollment (DEP / Apple Business Manager) status.

Why we looked at it:
Part of enterprise management services audit on macOS 27 Golden Gate.

Resource footprint:
~12–15 MB RAM across daemons when active.

Needed for coding / personal system:
No. Personal Macs not enrolled in corporate or educational MDM programs do not require ManagedClient. Disabling it prevents background enrollment network queries and speeds up system boot.

Disable:
```bash
sudo launchctl disable system/com.apple.ManagedClient
sudo launchctl disable system/com.apple.ManagedClient.startup
sudo launchctl disable system/com.apple.ManagedClient.enroll
sudo launchctl disable system/com.apple.ManagedClient.mechanism
sudo launchctl disable system/com.apple.mdmclient.daemon.runatboot
launchctl disable gui/<uid>/com.apple.ManagedClientAgent.agent
```

Test result:
Tested on macOS 27 Golden Gate. Rebooted cleanly. System, local accounts, and Settings operate 100% normally.
Verdict: **SAFE TO DISABLE FOR PERSONAL NON-MDM MACS (Risk 1)**.
