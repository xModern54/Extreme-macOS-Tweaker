# com.apple.systemadministration.writeconfig

## Basics

- **Process names:** `writeconfig`
- **Domain:** `system (XPCService)`
- **Bundle Path:** `/System/Library/PrivateFrameworks/SystemAdministration.framework/XPCServices/writeconfig.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/SystemAdministration.framework/XPCServices/writeconfig.xpc/Contents/MacOS/writeconfig`
- **Category:** `system_settings_admin_configuration_backend`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System Administration Configuration Writer Helper (`SystemAdministration.framework` / `writeconfig.xpc`).
Privileged XPC service responsible for:
1. **System Settings Persistence Backend**: Writes global administrative changes made in System Settings (Date & Time, Computer Name, Users & Groups, Power Management, Startup Disk) to `/Library/Preferences/SystemConfiguration/`.
2. **Administrative Authorization Enforcement**: Validates administrator credentials and authorization rights before applying low-level system configuration changes.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~3.7 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical core OS administrative backend. Disabling it breaks the ability to save system-level settings, rename computer, create user accounts, or change power management settings.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Core System Administration Infrastructure)**.
