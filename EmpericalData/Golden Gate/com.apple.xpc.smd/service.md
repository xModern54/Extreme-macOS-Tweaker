# com.apple.xpc.smd

## Basics

- **Process names:** `smd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.xpc.smd.plist`
- **Binary:** `/usr/libexec/smd`
- **Category:** `service_management_background_tasks`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Service Management Daemon — backend implementation for macOS `ServiceManagement.framework` (`SMAppService`, `SMJobBless`, `SMJobSubmit`).
Responsible for:
1. Managing and registering third-party Background Items and Login Items (System Settings -> General -> Login Items & Extensions).
2. Watching `/Library/LaunchDaemons/`, `/Library/LaunchAgents/`, and `~/Library/LaunchAgents/` via `fsevents`.
3. Validating and launching third-party privileged helper tools (Docker, Steam, brew services, Telegram, CleanMyMac, etc.).
4. Sending system notifications: "Background Items Added by developer X".

Why we looked at it:
Investigated during system background services survey on macOS 27 Golden Gate.

Resource footprint:
~2.7 MB RAM, 0.0% CPU.

Needed for coding:
Yes. Needed for any local developer tooling (Homebrew services, Docker desktop, background daemons).

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4)**.
Critical infrastructure daemon for launching all third-party software and background services.
