# Audio Diagnostics & Usage Telemetry Daemon — audioanalyticsd

## Basics

- **Main label:** `system/com.apple.audioanalyticsd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.audioanalyticsd.plist`
- **Binary:** `/usr/libexec/audioanalyticsd`
- **Domain:** `system`
- **Category:** `analytics_telemetry`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`audioanalyticsd` (Audio Diagnostics and Usage Reporting Daemon) is Apple's audio usage analytics and diagnostic collection daemon:

1. **Audio Usage Telemetry Collector**: Aggregates audio session data, microphone usage metrics, and sound output device statistics every 12 hours (`com.apple.bg.system.task`, interval 43200 seconds).
2. **Apple Product Improvement Telemetry**: Reports collected audio diagnostics back to Apple servers.

## What Is NOT Affected

- **Audio Playback & Recording Functionality**: Speakers, microphones, AirPods, sound output, audio recording apps, VSCode, Terminal, Git, Docker, SSH, and network operate **100% normally**.
- **System Telemetry**: Eliminates background periodic audio telemetry task.

## Disable

```bash
sudo launchctl bootout system/com.apple.audioanalyticsd 2>/dev/null || true
sudo launchctl disable system/com.apple.audioanalyticsd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.audioanalyticsd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.audioanalyticsd`.
2. Process `audioanalyticsd` disabled, eliminating background 12-hour audio telemetry reports.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `audioanalyticsd` remains disabled permanently (`"com.apple.audioanalyticsd" => disabled`).
   - Sound playback, recording, and all system functionality operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
