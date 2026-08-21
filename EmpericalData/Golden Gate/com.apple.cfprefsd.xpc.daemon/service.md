# com.apple.cfprefsd.xpc.daemon

## Basics

- **Process names:** `cfprefsd`
- **Domain:** `system`, `gui/<uid>`, `user/<uid>`
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.cfprefsd.xpc.daemon.plist`
  - `/System/Library/LaunchAgents/com.apple.cfprefsd.xpc.daemon.plist`
- **Binary:** `/usr/sbin/cfprefsd`
- **Category:** `core_foundation_preferences_storage`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
CoreFoundation Preferences Daemon (`cfprefsd`).
Central in-memory caching, synchronization, and disk persistence engine for **all macOS preferences and settings** (`~/Library/Preferences/*.plist`, `/Library/Preferences/`, `NSUserDefaults`, `CFPreferences`, `defaults read/write`).

Why we looked at it:
Found running in process table under root and user session.

Why it must NOT be disabled:
Disabling `cfprefsd` **completely breaks and crashes the entire macOS operating system**:
Every single application, framework, and daemon (from Finder, Terminal, Xcode to Tweaker itself) immediately hangs or crashes (SIGSEGV / Mach exception) upon attempting to read or write any setting.

Resource footprint:
2 instances consume ~8 MB RAM each, 0.0% CPU.

Needed for coding / system:
Yes. Absolutely mandatory core framework infrastructure.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Fatal OS Infrastructure)**.
