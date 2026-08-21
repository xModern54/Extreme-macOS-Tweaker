# com.apple.clocksyncd

## Basics

- **Process names:** `clocksyncd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.clocksyncd.plist`
- **Binary:** `/usr/libexec/clocksyncd`
- **Category:** `hardware_audio_ptp_clock_sync`
- **Risk:** `1`
- **Verdict:** `disable`

## Notes

What it does:
Precision Time Protocol (PTP / IEEE 1588) and TimeSync audio clock synchronization daemon (`clocksyncd`).
*Note on macOS 27:* Renamed from `com.apple.timesync.audioclocksyncd` (macOS 15–26) to **`com.apple.clocksyncd`** (macOS 27+).
Responsible for:
1. Sub-microsecond audio clock alignment across professional Ethernet audio interfaces (AVB / Dante) and multi-room AirPlay 2 speaker groups.
2. `com.apple.timesync.manager`, `com.apple.timesync.ptp.manager`, `com.apple.timesync.expositor`.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~7.1 MB RAM, 0.0% CPU.

Needed for coding / system:
No. Standard audio playback (MacBook speakers, 3.5mm jack, USB DAC, Bluetooth headphones, AirPods, YouTube, Zoom) continues to work 100% normally through `coreaudiod`.

Disable:
```bash
sudo launchctl bootout system/com.apple.clocksyncd
sudo launchctl disable system/com.apple.clocksyncd
```

Rollback:
```bash
sudo launchctl enable system/com.apple.clocksyncd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.clocksyncd.plist
```

Test result:
Tested on macOS 27 Golden Gate. Booted out and disabled. Verified standard audio playback with `afplay` — working completely normally.
Verdict: **SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE (Risk 1)**.
