# com.apple.appintents.LiveEntityService

## Basics

- **Process names:** `AppIntentsLiveEntityService`
- **Domain:** `pid/<pid> (XPCService)`
- **Bundle Path:** `/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/AppIntentsLiveEntitySupport.framework/XPCServices/AppIntentsLiveEntityService.xpc/Contents/MacOS/AppIntentsLiveEntityService`
- **Category:** `siri_appintents_live_entities`
- **Risk:** `1`
- **Verdict:** `disable-with-appintents`

## Notes

What it does:
Live App Entity cache and resolution coordinator for macOS 27 AppIntents 2.0 / Apple Intelligence.
Spawned by `mediaremoted` (or active media/interactive apps) to track live `@AppEntity` objects (current playing track, active timers, Live Activities, media player state).
Persists live entity state to `~/Library/Application Support/com.apple.appintents.LiveEntityService/` and bridges to `linkd` (`com.apple.linkd.mediator`, `com.apple.linkd.registry`, `com.apple.linkd.autoShortcut`).
Allows Siri AI and Spotlight to perform contextual actions on live objects (e.g. "Siri, pause what's playing", "Siri, add this song to playlist").

Why we looked at it:
Found running in process table under PID domain of `mediaremoted` on macOS 27 Golden Gate.

Resource footprint:
~9.5 MB RAM, 0.0% CPU.

Needed for coding / system:
No. Basic audio playback, keyboard media keys, and system sound work completely normally without it. Required only for Siri / AppIntents voice automation over live media and app states.

Verdict:
**DISABLE WITH APPINTENTS / SIRI STACK (Risk 1)**.
When `linkd` / Siri AI stack is disabled, this service idles or can be suppressed on SSV.
