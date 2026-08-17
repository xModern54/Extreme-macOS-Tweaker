# Managed Settings / Screen Time tail — `ManagedSettingsAgent` (ManagedSettingsAgent-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `ManagedSettingsAgent` only                                    |
| Category      | Family / Screen Time / Managed Settings disabled               |
| Risk Level    | 1–2 — enforcement/settings agent; not needed without family/ST |
| Profile       | **safe for no-Screen-Time / no-family coding target**          |

**Breaks:** Screen Time limits, FamilyControls restrictions, managed app/settings enforcement, local restriction surfaces  
**Should not break (headless verified):** SSH, login session; does not re-enable `askpermissiond` or `ScreenTimeAgent`

Completes family/Screen Time stack after:
- `com.apple.ScreenTimeAgent` (disabled)
- `com.apple.askpermissiond` (disabled, askpermissiond-off)
- `com.apple.familycircled`, `com.apple.familynotificationd` (disabled)

## What It Does

Per-user **ManagedSettings** agent — applies and publishes effective Screen Time / Family Controls / managed restrictions:

| Endpoint | Role |
|----------|------|
| `com.apple.ManagedSettingsAgent` | Main Mach service |
| `com.apple.ManagedSettingsAgent.publisher` | Publishes `effective-settings.changed` events |
| `com.apple.bg.system.task` | Post-install migration task |

Idle siblings on target: `FamilyControlsAgent`, `ScreenTimeSettingsAgent`, `familycontrols.useragent`, `AskPermissionUI`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.ManagedSettingsAgent` | gui | `ManagedSettingsAgent` | `/System/Library/LaunchAgents/com.apple.ManagedSettingsAgent.plist` |

**Binary:** `/System/Library/Frameworks/ManagedSettings.framework/Versions/A/ManagedSettingsAgent`

**Launch:** on-demand via Mach IPC (`immediate reason = ipc (mach)`).

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `ManagedSettingsAgent` | ~9.5 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.ManagedSettingsAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ManagedSettingsAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.ManagedSettingsAgent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **ManagedSettingsAgent-off**

**Before:** processes **291**, total RSS **4746 MB**, `ManagedSettingsAgent` running (~9.5 MB).

1. Bootout/disable `gui/502/com.apple.ManagedSettingsAgent` — gone immediately.
2. Reboot — SSH back ~18 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - `ManagedSettingsAgent`: **not running**; disable flag intact
   - **Delayed 40 s:** no respawn, no crash loop
   - **`askpermissiond`:** still disabled, not running
   - **`ScreenTimeAgent`:** still disabled, not running
   - **`FamilyControlsAgent` / `ScreenTimeSettingsAgent`:** still idle (not started)
   - **Log storm:** 0 boot lines for ManagedSettings/ScreenTime/FamilyControls/askpermission; 0 error/fail/retry
4. **After metrics:** processes **299–310**, total RSS **~4833–4923 MB** (~9.5 MB from agent removed; remainder boot variance)

**Verdict: keep disabled on coding experimental target.**

## Expected Breakage

- Screen Time limits and downtime enforcement surfaces.
- FamilyControls / managed app restrictions.
- Effective-settings propagation to apps that query ManagedSettings.
- Possible local MDM-style restriction reads (unlikely on unmanaged coding Mac).

**Not broken (verified headless):** SSH; family stack remains down; no collateral respawn of `askpermissiond` or `ScreenTimeAgent`.

## Notes

- Final slice of Screen Time / family permission stack on this target (with `ScreenTimeAgent` + `askpermissiond` already off).
- Distinct from MDM `remotemanagementd` wave (already disabled) — this is **local** managed settings agent.
- Re-enable only if using Screen Time, Family Controls, or managed restrictions on this Mac.