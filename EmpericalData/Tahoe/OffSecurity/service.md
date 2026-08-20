# XProtect Subsystem — Built-in Antivirus & Malware Remediator

## Basics

- **Feature Group:** XProtect Signature & Remediator Scanner Stack
- **Main Labels:**
  - `system/com.apple.security.xprotectd`
  - `system/com.apple.XProtect.daemon.scan`
  - `system/com.apple.XProtect.daemon.scan.startup`
  - `system/com.apple.XprotectFramework.PluginService`
  - `gui/<uid>/com.apple.XProtect.agent.scan`
  - `gui/<uid>/com.apple.XProtect.agent.scan.startup`
  - `gui/<uid>/com.apple.XprotectFramework.PluginService`
- **Processes:** `xprotectd`, `XProtectBridgeService`, `XProtectPluginService`
- **Category:** `security_antivirus_xprotect`
- **Risk Level:** `2` (removes background YARA malware scanning; Gatekeeper `syspolicyd` kept)
- **Profile:** `aggressive / OffSecurity`

## What It Does

XProtect is Apple's built-in background malware detection and removal subsystem:

1. **`xprotectd`**: Legacy YARA signature scanner for downloaded files.
2. **`XProtectRemediator` (`XProtect.daemon.scan` & `XProtectBridgeService`)**: Periodic background malware scanner that scans system disk and RAM for active malware signatures.
3. **`XProtectPluginService`**: Plugin worker processes serving malware scan requests.

## Kept Intact (Per Instructions)

- **`syspolicyd` (`/usr/libexec/syspolicyd`)**: Gatekeeper system policy daemon remains **KEPT ENABLED AND ACTIVE** (PID 256).

## What Is NOT Affected

- **Gatekeeper App Signature Checking**: Handled by `syspolicyd` (remains active).
- **System Stability & Developer Workflow**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, browsers, and graphics operate without any issues.

## Disable

```bash
uid=$(id -u)
# User domain
for label in com.apple.XProtect.agent.scan com.apple.XProtect.agent.scan.startup com.apple.XprotectFramework.PluginService; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done

# System domain
for label in com.apple.security.xprotectd com.apple.XProtect.daemon.scan com.apple.XProtect.daemon.scan.startup com.apple.XprotectFramework.PluginService; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.XProtect.agent.scan com.apple.XProtect.agent.scan.startup com.apple.XprotectFramework.PluginService; do
  launchctl enable "gui/$uid/$label"
done
for label in com.apple.security.xprotectd com.apple.XProtect.daemon.scan com.apple.XProtect.daemon.scan.startup com.apple.XprotectFramework.PluginService; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. Disabled all 7 XProtect jobs across `system` and `gui/502` domains.
2. Terminated `xprotectd`, `XProtectBridgeService`, `XProtectPluginService`.
3. Freed **~42MB RSS RAM** and eliminated periodic background 100-200% CPU malware scanning spikes.
4. Confirmed `syspolicyd` remains **running and active**.
5. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
6. Target Mac rebooted and SSH recovered in 12 seconds.
7. Post-reboot health check passed (`HEALTH RESULT: PASS`).
8. Confirmed:
   - All XProtect processes remain stopped (`pgrep -fl xprotect` -> 0).
   - `syspolicyd` remains running (PID 256).
   - Log audit confirmed 0 errors or retry loops.
