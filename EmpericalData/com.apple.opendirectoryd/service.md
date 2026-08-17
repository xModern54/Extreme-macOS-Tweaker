# Directory Services & User Authentication Node Daemon — opendirectoryd

## Basics

- **Main label:** `system/com.apple.opendirectoryd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.opendirectoryd.plist`
- **Binary:** `/usr/libexec/opendirectoryd`
- **Domain:** `system`
- **Category:** `auth_security_opendirectory`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`opendirectoryd` (Open Directory Daemon) is Apple's primary Directory Services and user authentication node daemon:

1. **User Authentication & Authorization Engine (`/var/db/dslocal/`)**: Validates user passwords, `sudo` elevation, SSH authentication, Touch ID authorization, and UID/GID membership checks for all local user accounts (`admin`, `staff`, `wheel`).
2. **Directory Services API Provider (`com.apple.system.opendirectoryd.membership`)**: Provides DirectoryService node APIs across the OS.

## Why It Must Remain Enabled

- Disabling `opendirectoryd` **completely breaks all user login, password authentication, `sudo` privileges, and SSH access across macOS**, triggering kernel panics (`PanicOnConsecutiveCrash`).
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
