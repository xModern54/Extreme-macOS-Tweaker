# Family / Ask To Buy — `askpermissiond` (askpermissiond-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `askpermissiond` only                                          |
| Category      | Family / Ask To Buy / permission prompts disabled              |
| Risk Level    | 1–2 — consumer family permission UI; not needed for coding     |
| Profile       | **safe for no-family / no-Ask-To-Buy coding target**           |

**Breaks:** Ask To Buy prompts, family permission flows, related managed permission UI  
**Should not break (headless verified):** SSH, core GUI session, `ManagedSettingsAgent` (still running)

Related prior disables: `com.apple.ScreenTimeAgent`, `com.apple.familycircled`, `com.apple.familynotificationd`, `com.apple.usernoted` (notifications dead).

## What It Does

Per-user **Ask Permission** daemon — Screen Time / Family / Ask To Buy style permission prompts:

| Endpoint / trigger | Role |
|--------------------|------|
| `com.apple.askpermissiond` | Main Mach service |
| `com.apple.aps.askpermission` | Push for permission requests |
| `com.apple.usernotifications.delegate.com.apple.askpermission.notifications` | UserNotifications delegate |
| `RunAtLoad` | true — normally starts at login |
| `distnoted` / `usernotificationcenter` | Language + notification events |

Idle siblings (not running on target): `AskPermissionUI`, `FamilyControlsAgent`, `familycontrols.useragent`, `ScreenTimeSettingsAgent`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.askpermissiond` | gui | `askpermissiond` | `/System/Library/LaunchAgents/com.apple.askpermissiond.plist` |

**Binary:** `/System/Library/PrivateFrameworks/AskPermission.framework/Versions/A/Resources/askpermissiond`

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `askpermissiond` | ~14 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.askpermissiond" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.askpermissiond"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.askpermissiond"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **askpermissiond-off**

**Before:** processes **305**, total RSS **5142 MB**, `askpermissiond` running (~14 MB).

1. Bootout/disable `gui/502/com.apple.askpermissiond` — gone immediately.
2. Reboot — SSH back ~18 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - `askpermissiond`: **not running** despite `RunAtLoad=true` in plist; disable flag intact
   - **Delayed 40 s:** no respawn, no crash loop
   - **Log storm:** 0 boot lines for askpermission/AskPermission; 0 error/fail/retry lines
4. **After metrics:** processes **302–309**, total RSS **~4850–4981 MB** (~14–290 MB delta vs before; ~14 MB attributable to `askpermissiond`)
5. **Nearby unchanged:** `ManagedSettingsAgent` still running (~9.5–10 MB); `ScreenTimeAgent` still disabled; `AskPermissionUI` / `FamilyControlsAgent` still idle

**Verdict: keep disabled on coding experimental target.**

## Expected Breakage

- Ask To Buy approval prompts.
- Family permission / parent-gate flows.
- Some managed/Screen Time permission surfaces that route through AskPermission (Screen Time enforcement already disabled separately).

**Not broken (verified headless):** SSH, login session, `ManagedSettingsAgent` presence.

## Notes

- Category bundles with family/Screen Time cuts; distinct from `ScreenTimeAgent` (enforcement) — this is **prompt/delivery** layer.
- `RunAtLoad=true` but `launchctl disable` prevents start after reboot — stable.
- Next optional slice in same category: `ManagedSettingsAgent` (separate experiment; still running).