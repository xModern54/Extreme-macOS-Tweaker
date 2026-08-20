# New Device Outreach / onboarding — `ndoagent` (ndoagent-off)

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | `ndoagent` only                                              |
| Category      | New Device Outreach / onboarding prompts disabled            |
| Risk Level    | 1 — setup/outreach agent; not needed on configured coding Mac |
| Profile       | **safe for no-onboarding coding target**                     |

**Breaks:** New-device onboarding prompts, Apple feature outreach, AppleCare push handler surfaces, setup education follow-ups tied to NDO  
**Should not break (headless verified):** SSH, login session, networking

## What It Does

Per-user **NewDeviceOutreach** agent — first-run / new-device onboarding and Apple outreach:

| Trigger / endpoint | Role |
|--------------------|------|
| `com.apple.NewDeviceOutreach.*CheckIn` | Background setup check-ins via `dasd` (network) |
| `AppleAccountAdded` | React when Apple ID is added |
| `com.apple.bluetooth.pairing` | React on BT pairing |
| `com.apple.language.changed` | React on locale change |
| `com.apple.aps.applecare.push.handler` | AppleCare push |
| `com.apple.ndoagent` | Main Mach/XPC service |

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.ndoagent` | gui | `ndoagent` | `/System/Library/LaunchAgents/com.apple.ndoagent.plist` |

**Binary:** `/System/Library/PrivateFrameworks/NewDeviceOutreach.framework/ndoagent`

**Launch:** no `RunAtLoad`; starts on XPC/background events.

**Not the same as:** `com.apple.followupd` (CoreFollowUp) — separate follow-up UI daemon; was already running before/after this test and was not disabled.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `ndoagent` | ~12 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.ndoagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ndoagent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.ndoagent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **ndoagent-off**

**Before:** processes **285**, total RSS **4721 MB**, `ndoagent` running (~12 MB).

1. Bootout/disable `gui/502/com.apple.ndoagent` — gone immediately.
2. Reboot — SSH back ~21 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `ndoagent`: **not running**; disable flag intact
   - **Delayed 25 s:** no respawn, no crash loop
   - **Neighbors:** `followupd` still running (~6 MB) as before — pre-existing, not new collateral; `tipsd` / `FollowUpUI` remain idle
   - **Log storm:** 0 boot lines for ndoagent/NewDeviceOutreach; 0 error/fail/retry
4. **After metrics:** processes **293**, total RSS **4546 MB** (~12 MB from agent removed; remainder boot variance)

**Verdict: keep disabled on coding experimental target.**

## Expected Breakage

- New-device onboarding tips and setup flows.
- Apple feature outreach / education prompts via NDO.
- AppleCare push surfaces tied to `aps.applecare.push.handler`.

**Not broken (verified headless):** SSH; no unexpected NewDeviceOutreach respawn; `followupd` unchanged (separate stack).

## Notes

- User never uses new-device onboarding on this Mac.
- `tipsd` and `followupd` are related consumer stacks but separate labels — research separately if needed.
- Re-enable only if wanting Apple setup/outreach prompts on this Mac.