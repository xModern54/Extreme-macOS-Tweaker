# Biome Event Streams & Proactive Telemetry — BiomeAgent & biomed

## Basics

- **Main labels:** `gui/<uid>/com.apple.BiomeAgent`, `system/com.apple.biomed`, `gui/<uid>/com.apple.biomesyncd`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.BiomeAgent.plist`, `/System/Library/LaunchDaemons/com.apple.biomed.plist`
- **Binaries:** `/System/Library/PrivateFrameworks/BiomeStreams.framework/Support/BiomeAgent`, `/System/Library/PrivateFrameworks/BiomeStreams.framework/Support/biomed`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `telemetry_proactive_biome`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`BiomeAgent` and `biomed` form Apple's background user behavior logging and event stream engine:

1. **User Interaction Event Logging**: Captures application launches, window focus changes, media playback, search queries, and system state transitions into local binary databases in `~/Library/Biome/` and `/var/db/biome/`.
2. **Intelligence Platform Core Dataset**: Generates 2-hour and 4-hour vector snapshots (`ViewEvery2Hours`) to feed Siri proactive suggestions and app prediction models.
3. **Database Maintenance**: Executes nightly compression and pruning tasks (`database-maintenance.nightly-task`) on local event databases.

## What Is NOT Affected

- **Application Functionality & Developer Tools**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, browsers, and graphics operate **100% normally**.
- **Manual App Launches & Navigation**: Launching applications, opening files, and operating macOS proceed without any issues.
- **Disk I/O**: Eliminates periodic 2-hour background disk writes to `~/Library/Biome/`.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.BiomeAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.BiomeAgent"
sudo launchctl bootout system/com.apple.biomed 2>/dev/null || true
sudo launchctl disable system/com.apple.biomed
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.BiomeAgent"
sudo launchctl enable system/com.apple.biomed
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.BiomeAgent` and `system/com.apple.biomed`.
2. Processes `BiomeAgent` and `biomed` terminated, releasing **~36.2MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `BiomeAgent` and `biomed` processes remain stopped.
   - System stability and application performance operate normally.
   - Log audit confirmed 0 errors or retry loops.