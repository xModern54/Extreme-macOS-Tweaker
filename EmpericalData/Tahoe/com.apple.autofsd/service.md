# Automount Filesystem Daemon — autofsd

## Basics

- **Main label:** `system/com.apple.autofsd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.autofsd.plist`
- **Binary:** `/usr/libexec/autofsd`
- **Domain:** `system`
- **Category:** `disk_apfs_nfs_smb_mounting`
- **Risk:** `1` (for standard coding workflows) / `2` (Conditional for corporate NFS automount users)
- **Verdict:** `disable for coding profile`

## What It Does

`autofsd` (Automount Filesystem Daemon) is Apple's `autofs` network share transparent automounting daemon:

1. **Transparent NFS/SMB Automount Engine (`/net/`)**: Monitors `/net` and `/etc/auto_master` mount points, transparently connecting network NFS/SMB file shares when paths under `/net/` are accessed by scripts or applications.
2. **Idle Unmount Manager**: Automatically unmounts inactive `autofs` network shares after timeout periods.

## What Is NOT Affected

- **Normal SMB/NFS Shares & Finder Connections**: Manual network share connections in Finder (*Cmd+K -> smb://...*), USB flash drives, external SSDs, APFS volumes, VSCode, Terminal, Git, Docker, SSH, and Wi-Fi operate **100% normally**.
- **System Memory**: Eliminates persistent daemon, freeing **~10MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.autofsd 2>/dev/null || true
sudo launchctl disable system/com.apple.autofsd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.autofsd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.autofsd`.
2. Process `autofsd` terminated, releasing **~10MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `autofsd` process remains stopped permanently.
   - Normal Finder network mounting (`smb://`), local drives, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
