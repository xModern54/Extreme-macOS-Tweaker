# com.apple.tailspind

## Basics

- **Process names:** `tailspind`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.tailspind.plist`
- **Binary:** `/usr/libexec/tailspind`
- **Category:** `diagnostics_profiling_ktrace`
- **Risk:** `0`
- **Verdict:** `disable`

## Notes

What it does:
Kernel trace and hang profiling daemon (`ktrace` / `tailspin`).
Continuously monitors system responsiveness and captures circular buffer traces of thread callstacks when UI hangs, spinning beachballs, or micro-freezes occur.
Writes diagnostic trace files to `/var/db/tailspin/`.

Why we looked at it:
Investigated during process table scan on macOS 27 Golden Gate.

Resource footprint:
~4.8 MB RAM, 0.0% CPU.

Needed for coding / system:
No. Purely diagnostic profiling telemetry for Apple. Regular applications, Finder, and system processes run completely unaffected without tailspin trace generation.

Disable:
```bash
sudo launchctl bootout system/com.apple.tailspind
sudo launchctl disable system/com.apple.tailspind
```

Rollback:
```bash
sudo launchctl enable system/com.apple.tailspind
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.tailspind.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely booted out and disabled. System operates normally with zero side effects.
Verdict: **SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE (Risk 0)**.
