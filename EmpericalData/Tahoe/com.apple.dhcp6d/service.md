# Stateless DHCPv6 Internet Sharing Daemon — dhcp6d

## Basics

- **Main label:** `system/com.apple.dhcp6d`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.dhcp6d.plist`
- **Binary:** `/usr/libexec/dhcp6d`
- **Domain:** `system`
- **Category:** `networking_internet_sharing`
- **Risk:** `1` (for standard single-device Mac workflows) / `2` (Conditional if using Mac as an Internet Sharing Wi-Fi hotspot)
- **Verdict:** `disable for coding profile`

## What It Does

`dhcp6d` (Stateless DHCPv6 Server Daemon) is Apple's IPv6 dynamic host configuration protocol server backing the macOS Internet Sharing feature (`InternetSharing`):

1. **IPv6 Hotspot Address Allocation**: Assigns IPv6 addresses and routing configuration options to external clients connecting when the Mac is configured as an Internet Sharing hotspot (sharing Wi-Fi/Ethernet connections to other devices).
2. **Stateless DHCPv6 Configuration**: Serves DNS server options and domain search lists to connected devices over IPv6.

## What Is NOT Affected

- **Normal Wi-Fi, Ethernet, Internet & Network Access**: Standard Wi-Fi, Ethernet, DNS resolution, SSH, Git, Docker, VSCode, and internet browsing operate **100% normally**.
- **System Memory**: Eliminates unused network sharing daemon.

## Disable

```bash
sudo launchctl bootout system/com.apple.dhcp6d 2>/dev/null || true
sudo launchctl disable system/com.apple.dhcp6d
```

## Rollback

```bash
sudo launchctl enable system/com.apple.dhcp6d
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.dhcp6d`.
2. Daemon `dhcp6d` disabled in launchd.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `dhcp6d` remains disabled permanently (`"com.apple.dhcp6d" => disabled`).
   - Normal Wi-Fi, Ethernet, DNS resolution, and SSH operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
