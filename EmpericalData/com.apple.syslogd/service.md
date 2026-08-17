# System POSIX Logging & Socket Host Daemon — syslogd

## Basics

- **Main label:** `system/com.apple.syslogd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.syslogd.plist`
- **Binary:** `/usr/sbin/syslogd`
- **Domain:** `system`
- **Category:** `system_logging_syslogd`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`syslogd` (Apple System Logger Daemon) is Apple's BSD POSIX `syslog()` socket host daemon (`com.apple.system.logger`):

1. **POSIX UNIX Socket Provider (`/var/run/syslog`)**: Provides the standard `/var/run/syslog` UNIX domain socket used by POSIX C/C++ binaries, `sudo`, `ssh`, `sshd`, Homebrew packages, and command-line utilities when emitting `syslog()` messages.
2. **Unified Logging Bridge**: Forwards incoming POSIX syslog socket messages into `logd` (`os_log`).

## Why It Must Remain Enabled

- Disabling `syslogd` **removes the `/var/run/syslog` socket, causing command-line utilities (`sudo`, `ssh`, `sshd`, C/C++ compilers) to hang or fail with `socket failed: No such file or directory`**.
- Explicitly listed in `AGENTS.md` core protected infrastructure guidelines (`syslogd`).

## Status

**KEPT ENABLED AND PROTECTED.**
