# com.apple.spindump / com.apple.spindump_agent

## Basics

- **Process names:** `spindump`, `spindump_agent`
- **Domain:** `system` (`com.apple.spindump`) and `gui/<uid>` (`com.apple.spindump_agent`)
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.spindump.plist`
  - `/System/Library/LaunchAgents/com.apple.spindump_agent.plist`
- **Binary:** `/usr/sbin/spindump`, `/usr/libexec/spindump_agent`
- **Category:** `diagnostics_profiling_hang_reporting`
- **Risk:** `0`
- **Verdict:** `disable`

## Notes

What it does:
System hang and unresponsive process stack sampler (`spindump`).
When an application stops responding to UI events (spinning beach ball) or enters an infinite CPU spin, `spindump` samples thread backtraces every 10ms to produce a `.hang` / `.spindump.txt` report in `/Library/Logs/DiagnosticReports/`.
Works in tandem with `tailspind` (which captures system-wide `ktrace` circular buffers).

Why we looked at it:
Part of the macOS hang profiling & diagnostic reporting stack.

Resource footprint:
~6 MB RAM, 0.0% CPU when idle; CPU spike during stack sampling.

Needed for coding / system:
No. Purely diagnostic telemetry for Apple developers. Disabling it does not prevent Force Quit or window unresponsiveness detection (which is handled by `WindowServer`), but avoids disk I/O and report generation.

Disable:
```bash
sudo launchctl bootout system/com.apple.spindump
sudo launchctl disable system/com.apple.spindump
launchctl bootout gui/<uid>/com.apple.spindump_agent
launchctl disable gui/<uid>/com.apple.spindump_agent
```

Rollback:
```bash
sudo launchctl enable system/com.apple.spindump
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.spindump.plist
launchctl enable gui/<uid>/com.apple.spindump_agent
launchctl bootstrap gui/<uid> /System/Library/LaunchAgents/com.apple.spindump_agent.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely disabled and rebooted cleanly.
Verdict: **SAFE TO DISABLE / EXCELLENT TWEAK CANDIDATE (Risk 0)**.
