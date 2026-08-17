# Intelligent AirPlay & Media Proximity Routing — intelligentroutingd

## Basics

- **Main label:** `com.apple.intelligentroutingd`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.intelligentroutingd.plist`
- **Binary:** `/usr/libexec/intelligentroutingd`
- **Domain:** `gui/<uid>`
- **Category:** `media_routing_airplay_proximity`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`intelligentroutingd` (Intelligent Media Routing Daemon) is Apple's background media output routing heuristics manager (introduced in macOS Sonoma / iOS 17):

1. **Smart AirPlay Banners**: Evaluates Biome Streams (`com.apple.biome.compute.publisher.user`) and Bluetooth proximity to trigger UI banner prompts suggesting audio/video output routing to nearby HomePod speakers or Apple TV devices.
2. **AirPods Proximity Switching**: Participates in heuristic logic for automatic audio takeover across devices.

## What Is NOT Affected

- **Manual Audio & AirPlay Device Selection**: Selecting headphones, speakers, Bluetooth audio devices, or AirPlay outputs manually via Control Center / Sound Settings operates via `coreaudiod` and `audiomxd` and remains **100% functional**.
- **System Stability & Audio**: Media playback in Safari, IDEs, terminals, and audio players is fully unaffected.

## Verdict

`com.apple.intelligentroutingd` is Apple ecosystem proximity bloat (Smart AirPlay banners). Safe to disable on coding profile.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.intelligentroutingd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.intelligentroutingd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.intelligentroutingd"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `launchctl bootout` and `launchctl disable` applied for `gui/502/com.apple.intelligentroutingd`.
2. Process `intelligentroutingd` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `intelligentroutingd` process remains stopped.
   - Manual sound output selection works normally.
   - Log audit confirmed 0 errors or retry loops.
