# Media Remote Control & Now Playing Daemon — mediaremoted

## Basics

- **Main label:** `system/com.apple.mediaremoted`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.mediaremoted.plist`
- **Binary:** `/System/Library/PrivateFrameworks/MediaRemote.framework/Support/mediaremoted`
- **Domain:** `system`
- **Category:** `hardware_media_playback_nowplaying_remote`
- **Risk:** `2` (conditional: keep enabled if user uses hardware F7/F8/F9 playback keys or Now Playing widget)
- **Verdict:** `CONDITIONAL / RESTORED — KEEP ENABLED FOR MEDIA KEYS`

## What It Does

`mediaremoted` (Media Remote Daemon) manages Apple's hardware media control keys, Now Playing widget events, and AirTunes DACP protocols:

1. **Hardware Media Playback Keys (F7/F8/F9 & Headset Controls)**: Intercepts Play, Pause, Next Track, and Previous Track hardware key triggers (`AirTunes.DACP.play`, `DACP.pause`, `DACP.nextitem`) and routes them to the active media player.
2. **Now Playing Widget & AirPlay Metadata Dispatcher**: Dispatches track metadata, album artwork, and playback progress to Control Center and AirPlay devices.

## Why It Was Restored

- Disabling `mediaremoted` disables hardware media control keys F7/F8/F9 and Now Playing widget integration. Restored per user preference.

## Rollback / Restore Command

```bash
sudo launchctl enable system/com.apple.mediaremoted
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.mediaremoted.plist
sudo shutdown -r now
```

## Status

**RESTORED AND KEPT ENABLED FOR HARDWARE MEDIA KEYS.**
