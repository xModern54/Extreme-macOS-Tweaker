# com.apple.UserEventAgent

## Basics

- **Process names:** `UserEventAgent`
- **Domain:** `system` (`com.apple.UserEventAgent-System`), `gui/<uid>` (`com.apple.UserEventAgent-Aqua`)
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.UserEventAgent-System.plist`
  - `/System/Library/LaunchAgents/com.apple.UserEventAgent-Aqua.plist`
- **Binary:** `/usr/libexec/UserEventAgent`
- **Category:** `system_event_dispatcher`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Core System Event Plugin Host and `launchd` Event Dispatcher (`UserEventAgent`).
Responsible for:
1. **Hardware & Power Events**: Monitors external drive connections (USB/Thunderbolt), auto-mounting, display connection/disconnection, power source transitions (AC/battery), and sleep/wake cycles.
2. **Launchd Event Streams (`LaunchEvents`)**: Observes `com.apple.iokit.matching`, `com.apple.notifyd.matching`, `com.apple.fsevents.matching`, and `com.apple.xpc.activity` event channels on behalf of `launchd`.
3. **Plugin Host**: Loads plugins from `/System/Library/UserEventPlugins/` to handle system events.

Why we looked at it:
Investigated during core system daemons audit on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `UserEventAgent` **completely breaks hardware event dispatching, drive mounting, display detection, and launchd event processing across the entire operating system**.

Resource footprint:
2 instances consume ~21 MB (System) and ~20 MB (Aqua) RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical system infrastructure.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Core System Infrastructure)**.
