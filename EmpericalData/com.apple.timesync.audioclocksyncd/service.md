# Audio Clock Precision Time Sync Daemon — audioclocksyncd

## Basics

- **Main label:** `system/com.apple.timesync.audioclocksyncd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.timesync.audioclocksyncd.plist`
- **Binary:** `/usr/libexec/audioclocksyncd`
- **Domain:** `system`
- **Category:** `core_macos_audio_clock_sync`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`audioclocksyncd` (Audio Clock Synchronization Daemon) is Apple's background Precision Time Protocol (PTP / IEEE 1588) manager:

1. **Sub-microsecond Audio Clock Alignment (`com.apple.timesync.ptp.manager`)**: Synchronizes crystal oscillator clock drift across network audio interfaces (AVB / Dante) and multi-room AirPlay 2 speaker setups.
2. **TimeSync Expositor**: Exposes clock drift metrics for professional multi-channel Ethernet studio audio setups.

## What Is NOT Affected

- **Standard Audio Playback**: Built-in MacBook speakers, 3.5mm headphone jack, USB headsets, Bluetooth headphones, AirPods, YouTube/video playback, and Zoom/Slack calls operate **100% normally** via `coreaudiod`.
- **System Performance & Developer Tools**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, and browsers run without any degradation.

## Disable

```bash
sudo launchctl bootout system/com.apple.timesync.audioclocksyncd 2>/dev/null || true
sudo launchctl disable system/com.apple.timesync.audioclocksyncd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.timesync.audioclocksyncd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.timesync.audioclocksyncd`.
2. Process `audioclocksyncd` terminated, releasing **~7.1MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `audioclocksyncd` process remains stopped.
   - Standard audio playback and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
