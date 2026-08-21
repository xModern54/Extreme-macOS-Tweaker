# com.apple.powerchime

## Basics

- **Process names:** `PowerChime`
- **Domain:** `gui/<uid>`
- **Plist:** `/System/Library/LaunchAgents/com.apple.powerchime.plist`
- **Binary:** `/System/Library/CoreServices/PowerChime.app/Contents/MacOS/PowerChime`
- **Category:** `hardware_power_audio_effects`
- **Risk:** `0`
- **Verdict:** `disable`

## Notes

What it does:
Plays the iOS/Mac power chime sound when connecting MagSafe or USB-C charging cable.
Woken up by `LaunchEvents`: `com.apple.notifyd.matching` -> `com.apple.system.powersources.source`.

Why we looked at it:
Found running in user session consuming **~37 MB RAM** permanently.

Resource footprint:
**~37 MB RAM**, 0.0% CPU.

Needed for coding / system:
No. Power management (`powerd`), battery charging, MagSafe LED indicator, and battery status in menu bar continue to work completely normally. The only difference is silence when connecting the charger.

Disable:
```bash
launchctl bootout gui/<uid>/com.apple.powerchime
launchctl disable gui/<uid>/com.apple.powerchime
```

Rollback:
```bash
launchctl enable gui/<uid>/com.apple.powerchime
launchctl bootstrap gui/<uid> /System/Library/LaunchAgents/com.apple.powerchime.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely terminated, instantly freed 37 MB RAM. Charging and power management completely unaffected.
Verdict: **SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE (Risk 0)**.
