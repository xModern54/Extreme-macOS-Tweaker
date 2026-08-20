# Obsolete HDD Boot Cache Prewarming Daemon — warmd

## Basics

- **Main label:** `system/com.apple.warmd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.warmd.plist`
- **Binary:** `/usr/libexec/warmd`
- **Domain:** `system`
- **Category:** `system_boot_cache_prewarming`
- **Risk:** `1` (for NVMe SSD / Apple Silicon systems)
- **Verdict:** `disable for coding profile`

## What It Does

`warmd` (Warm Boot & Cache Prewarming Daemon) is a legacy macOS boot-time read-ahead prewarming daemon designed during the HDD era:

1. **HDD Read-Ahead Prewarming**: Pre-loaded file blocks from `/var/db/warmd/` into RAM during system boot to reduce disk head seek latency on mechanical hard drives.
2. **Apple Silicon & NVMe SSD Status**: On modern Apple Silicon Macs (M1/M2/M3/M4) with high-speed NVMe SSDs (4000+ MB/s), macOS disables the underlying kernel `BootCache` driver (`BootCache_Start: 0`). `warmd` runs idle (`LowPriorityIO`) and fails to send telemetry metrics to `analyticsd`.

## What Is NOT Affected

- **System Boot Speed & NVMe SSD Performance**: Target Mac reboot speed remains identical (10 seconds), and application launching operates **100% normally**.
- **Developer Tools & Applications**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, and sound run without any degradation.

## Disable

```bash
sudo launchctl bootout system/com.apple.warmd 2>/dev/null || true
sudo launchctl disable system/com.apple.warmd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.warmd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.warmd`.
2. Process `warmd` terminated, releasing **~11MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `warmd` process remains stopped.
   - Boot speed (10s) and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
