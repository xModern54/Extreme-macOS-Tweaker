# System Authorization Rights Daemon — authd

## Basics

- **Main label:** `system/com.apple.authd`
- **Plist path:** Embedded system XPC bundle (`/System/Library/Frameworks/Security.framework/Versions/A/XPCServices/authd.xpc`)
- **Binary:** `/System/Library/Frameworks/Security.framework/Versions/A/XPCServices/authd.xpc/Contents/MacOS/authd`
- **Domain:** `system`
- **Category:** `auth_security_rights`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`authd` (Authorization Daemon) is Apple's primary system authorization rights engine managing `/var/db/auth.db`:

1. **Authorization Rights Database (`AuthorizationDB`)**: Manages access rules for administrative system operations, privilege escalation, preference modifications, and application installation tasks.
2. **`AuthorizationCopyRights` API Engine**: Validates privilege elevation requests and issues session security tokens upon successful Touch ID / administrative password entry.

## Why It Must Remain Enabled

- Disabling `authd` **completely breaks all macOS administrative authorization operations**, installer privilege requests, system setting unlocks, and Touch ID rights validation.

## Status

**KEPT ENABLED AND PROTECTED.**
