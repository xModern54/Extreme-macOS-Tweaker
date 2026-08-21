# com.apple.appintents.LiveEntityService

## Basics

- **Process names:** `AppIntentsLiveEntityService`
- **Domain:** `pid/<pid> (XPCService)`
- **Bundle Path:** `/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc/Contents/MacOS/AppIntentsLiveEntityService`
- **Category:** `siri_appintents_live_entities`
- **Risk:** `1`
- **Verdict:** `remove-via-ssv`

## Notes

What it does:
Live App Entity cache and resolution coordinator for macOS 27 AppIntents 2.0 / Apple Intelligence.
Automatically spawned by `mediaremoted` (or active media/interactive apps) to track live `@AppEntity` objects (current playing track, active timers, Live Activities, media player state).
Persists live entity state to `~/Library/Application Support/com.apple.appintents.LiveEntityService/` and bridges to `linkd` (`com.apple.linkd.mediator`, `com.apple.linkd.registry`, `com.apple.linkd.autoShortcut`).
Allows Siri AI and Spotlight to perform contextual actions on live objects (e.g. "Siri, pause what's playing", "Siri, add this song to playlist").

Why we looked at it:
Found running in process table under PID domain of `mediaremoted` on macOS 27 Golden Gate consuming ~9.8 MB RAM.

Why launchctl disable does not kill it:
Like `SetStoreUpdateService.xpc`, this is an in-app embedded XPC service (`ServiceType = Application`). It is spawned directly by `mediaremoted`'s Mach connection handle. `launchctl bootout` fails with `1: Operation not permitted`.

How to Neutralize (SSV System Volume Debloat):
To permanently prevent `mediaremoted` and other apps from spawning this XPC helper, isolate its bundle on the mounted Signed System Volume (`/Volumes/SystemRW`):
```bash
mv "/Volumes/SystemRW/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc" \
   "/Volumes/SystemRW/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc.disabled"
```
After creating a new APFS snapshot (`bless --create-snapshot`) and rebooting, `mediaremoted` will fail to spawn the XPC service, and 0 instances will run, saving ~10 MB RAM.

Needed for coding / system:
No. Basic audio playback, keyboard media keys (Play/Pause/F8/F9/F10), and system sound work completely normally without it.

Verdict:
**TARGET FOR SSV EMBEDDED XPC DEBLOAT (Risk 1)**.
Must be neutralized by isolating its XPC bundle on the system volume.
