# com.apple.notifyd

## Basics

- **Process names:** `notifyd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.notifyd.plist`
- **Binary:** `/usr/sbin/notifyd`
- **Category:** `core_ipc_notification_bus`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System IPC Asynchronous Event & Notification Dispatcher (`notifyd`).
Central hub for `notify(3)` C API (`notify_post`, `notify_register_dispatch`, `notify_check`, `libsystem_notify.dylib`).
Responsible for:
1. **Inter-Process Event Bus**: Broadcasts system-wide state change notifications (network connectivity changes, power source switching, display sleep/wake, volume changes, screen lock/unlock) across all running processes.
2. **`launchd` Event Stream Engine (`LaunchEvents`)**: Feeds all `com.apple.notifyd.matching` triggers that wake up background daemons on demand.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `notifyd` **causes immediate system-wide failure, lockups, and crashes across all macOS user and system processes** due to the collapse of the central IPC notification bus.

Resource footprint:
~5.3 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Absolutely mandatory core POSIX/Darwin operating system infrastructure.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Fatal OS Infrastructure)**.
