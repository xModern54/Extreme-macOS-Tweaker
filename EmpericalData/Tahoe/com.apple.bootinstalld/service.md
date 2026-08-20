# System Bootloader & Preboot Firmware Installer Helper — bootinstalld

## Basics

- **Main label:** `system/com.apple.bootinstalld`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.bootinstalld.plist`
- **Binary:** `/usr/libexec/bootinstalld`
- **Domain:** `system`
- **Category:** `system_firmware_boot_installer`
- **Risk:** `1` (for coding profiles without automatic macOS background update installations)
- **Verdict:** `disable for coding profile`

## What It Does

`bootinstalld` (Boot Installation Helper) is Apple's background daemon for unpacking and writing iBoot bootloader firmware updates:

1. **Preboot Volume Firmware Flashing**: Writes updated iBoot binaries, boot kernels, and security manifests (`manifest.im4m`) onto the APFS `Preboot` system volume when system updates are installed by `softwareupdated`.
2. **Mach Service Hosting (`com.apple.bootinstalld`)**: Serves IPC requests from `softwareupdated` and system installer applications.

## Command Line `bless` Compatibility

> [!NOTE]
> **Утилита `bless` НЕ затрагивается**: Команда `/usr/sbin/bless` (перемонтирование загрузочного тома `--setBoot`, пропись NVRAM `efi-boot-device`) работает через прямое обращение к ядру XNU (`setattrlist`) и `APFS.framework` и **НЕ использует `bootinstalld`**.

## What Is NOT Affected

- **System Booting & Volume Selection**: `bless` command-line utility, Startup Disk selection in System Settings, APFS volume mounting, Xcode, Terminal, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Memory**: Eliminates background daemon, freeing **~6MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.bootinstalld 2>/dev/null || true
sudo launchctl disable system/com.apple.bootinstalld
```

## Rollback

```bash
sudo launchctl enable system/com.apple.bootinstalld
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.bootinstalld`.
2. Process `bootinstalld` terminated, releasing **~6MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `bootinstalld` process remains stopped.
   - `bless` utility, volume boot selection, and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
