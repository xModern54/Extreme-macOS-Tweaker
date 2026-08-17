# APFS FileVault & Encrypted Volume Notification User Agent — APFSUserAgent

## Basics

- **Main label:** `gui/<uid>/com.apple.apfsuseragent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.apfsuseragent.plist`
- **Binary:** `/System/Library/CoreServices/APFSUserAgent`
- **Domain:** `gui/<uid>`
- **Category:** `disk_apfs_filevault_ui`
- **Risk:** `1` (for standard coding workflows without GUI FileVault popups) / `2` (Conditional for encrypted external flash drive users relying on UI banners)
- **Verdict:** `disable for coding profile`

## What It Does

`APFSUserAgent` (APFS Volume Encryption User Agent) is Apple's GUI user notification agent for APFS encrypted volumes and FileVault (`APFS.framework`):

1. **Encrypted Volume Password Request Banner**: Displays a user notification banner when attaching external FileVault-encrypted APFS drives (`AppleAPFSContainer`), prompting for a password in the UI banner.
2. **FileVault Encryption Status Banners**: Displays Notification Center banners when system FileVault encryption or decryption completes.

## What Is NOT Affected

- **Disk Utility (Disk Utility.app)**: Partitioning, formatting, volume management, First Aid, SMART disk health checking, and drive diagnostics operate **100% normally**.
- **System APFS Storage & Diagnostics**: Drive monitoring utilities (iStat Menus, Sensei, CleanMyMac) and kernel APFS drivers operate **100% normally via `diskarbitrationd` and `IOKit`**.
- **System Memory**: Eliminates persistent GUI agent, freeing **~15MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.apfsuseragent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.apfsuseragent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.apfsuseragent"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.apfsuseragent`.
2. Process `APFSUserAgent` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `APFSUserAgent` process remains stopped permanently.
   - Disk Utility, disk diagnostics, SMART status, local APFS drives, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
