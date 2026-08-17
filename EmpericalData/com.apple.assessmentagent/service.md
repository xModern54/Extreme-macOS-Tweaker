# Assessment / school exam lockdown — `assessmentagent` (assessmentagent-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `assessmentagent` only                                        |
| Category      | Assessment / school exam lockdown disabled — **бесполезный для coding** |
| Risk Level    | 1 — education/exam agent; not needed without school assessment |
| Profile       | **useless on personal coding Mac; keep disabled**             |

**Breaks:** Assessment mode, exam lockdown, school restriction policies, configuration-profile assessment recovery  
**Should not break (headless verified):** SSH, login session, networking

## What It Does

Per-user **Automatic Assessment Configuration** agent — school/testing lockdown infrastructure:

| Component | Role |
|-----------|------|
| `AEAPolicyStore` | Assessment policy storage |
| `AEARestrictionsApplicator` | Applies exam/school restrictions |
| `activeRestrictionUUIDFetching` | Fetches active restriction UUIDs |
| `AEADisableAssessmentModeTask` | Assessment mode lifecycle |
| Recovery markers | Config-profile recovery under `~/Library/Containers/com.apple.assessmentagent/` |

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.assessmentagent` | gui | `assessmentagent` | `/System/Library/LaunchAgents/com.apple.assessmentagent.plist` |

**Binary:** `/usr/libexec/assessmentagent` (`AutomaticAssessmentConfiguration`)

**Launch:** no `RunAtLoad`; starts on XPC event. `KeepAlive` when PolicyStore path exists.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `assessmentagent` | ~11 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.assessmentagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.assessmentagent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.assessmentagent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **assessmentagent-off**

**Before:** processes **280**, total RSS **4432 MB**, `assessmentagent` running (~11 MB).

1. Bootout/disable `gui/502/com.apple.assessmentagent` — gone immediately.
2. Reboot — SSH back ~21 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `assessmentagent`: **not running**; disable flag intact
   - **Delayed 25 s:** no respawn, no crash loop
   - **Neighbors:** no classroom/school/exam/education processes started
   - **Log storm:** 0 lines; 0 error/fail/retry
4. **After metrics:** processes **290**, total RSS **4537 MB** (~11 MB from agent removed; remainder boot variance)

**Verdict: keep disabled — бесполезный хвост для coding Mac.**

## Expected Breakage

- School exam / assessment mode lockdown.
- Managed assessment configuration profiles.
- Restriction enforcement during standardized testing.

**Not broken (verified headless):** SSH; no collateral education stack respawn.

## Notes

- PolicyStore was empty on target — agent idle, only recovery marker container present.
- Personal coding Mac with no school MDM/assessment use — safe dead weight.
- Re-enable only if using Apple assessment/school lockdown on this Mac.