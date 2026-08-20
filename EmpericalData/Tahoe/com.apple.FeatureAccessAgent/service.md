# iCloud subscription / cloud feature access — `FeatureAccessAgent` (FeatureAccessAgent-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `FeatureAccessAgent` only                                      |
| Category      | iCloud subscription / cloud feature access disabled          |
| Risk Level    | 2 — iCloud feature-gating agent; low headless impact observed  |
| Profile       | **keep disabled on no-iCloud+-features coding target**         |

## What It Does (за что отвечает)

Per-user **CloudSubscriptionFeatures** agent — manages **iCloud subscription status** and **cloud feature availability** (man: *iCloud Subscription Status Management*, macOS 15+).

| Responsibility | Detail |
|----------------|--------|
| Feature gating | Which iCloud / cloud subscription features are available to this user/device |
| Mach API | `com.apple.ind.cloudfeatures` — answers feature-access queries from system components |
| Network cache | HTTP + SQLite under `~/Library/HTTPStorages/com.apple.FeatureAccessAgent/` and `~/Library/Caches/com.apple.FeatureAccessAgent/` |
| Periodic reload | `com.apple.featureaccess.reload` (network, repeating utility task) |
| Event-driven refresh | First unlock, language change, device pair, device rename, Photos iCloud state, iCloud quota/VFS simulation events |

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.FeatureAccessAgent` | gui | `FeatureAccessAgent` | `/System/Library/LaunchAgents/com.apple.FeatureAccessAgent.plist` |

**Binary:** `/System/Library/PrivateFrameworks/CloudSubscriptionFeatures.framework/FeatureAccessAgent`

**Launch:** no `RunAtLoad`; starts on Mach IPC (`immediate reason = ipc (mach)`).

## Who Was Calling It (до disable)

| Source | Finding |
|--------|---------|
| Unified logs (30m / 7d before) | **0** FeatureAccess / cloudfeatures traffic — agent idle in logs |
| Active XPC clients at snapshot | **none visible** via `lsof` on Mach port; only self-owned cache/HTTP sqlite files |
| Boot trigger | Launched at login via Mach IPC bootstrap, not steady client churn |
| Known related consumer | `com.apple.generativeexperiencesd` listens for `com.apple.CloudSubscriptionFeatures.OptIn.Changed` — **already disabled** on target before this test |
| iCloud auth stack | `akd` running (~18 MB) — no logged FeatureAccess coupling at test time |

**Conclusion:** on this target the agent was a **standing ~23 MB cache holder**, not an actively chatted-with daemon during the observation window.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `FeatureAccessAgent` | ~23 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.FeatureAccessAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.FeatureAccessAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.FeatureAccessAgent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **FeatureAccessAgent-off**

**Before:** processes **293**, total RSS **4528 MB**, `FeatureAccessAgent` running (~23 MB).

1. Bootout/disable `gui/502/com.apple.FeatureAccessAgent` — gone immediately.
2. Reboot — SSH back ~18 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `FeatureAccessAgent`: **not running**; disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 FeatureAccess/cloudfeatures/CloudSubscription lines; 0 error/fail/retry/denied
   - **Neighbors — did NOT start/noise:**
     - `generativeexperiencesd` — remains disabled, not running
     - no new `FeatureAccess` / `CloudSubscription` processes
   - **Neighbors — still running, quiet:**
     - `akd` (~18 MB) — no new error/retry logs tied to FeatureAccess
     - `bird`, `CloudDocs` iCloudDrive FP, `ContainerMetadataExtractor` — normal iCloud stack, no extra log noise
4. **After metrics:** processes **289**, total RSS **4508 MB** (~20–23 MB from agent removed)

**Verdict: keep disabled on coding experimental target.**

## What Breaks (expected, GUI not tested)

- iCloud subscription / cloud feature availability queries via `com.apple.ind.cloudfeatures`.
- Cached cloud-feature gates that depend on FeatureAccess reload/network fetch.
- Possible impact on surfaces that read CloudSubscriptionFeatures opt-in state (e.g. Apple Intelligence / iCloud+ gated UI) if re-enabled elsewhere.

**Not broken (verified headless):** SSH; no respawn; no neighbor log storm; core iCloud daemons (`akd`, `bird`) still up without FeatureAccess retry loops.

## Neighbor Map

| Neighbor | Relation | Before | After disable + reboot |
|----------|----------|--------|-------------------------|
| `generativeexperiencesd` | listens `CloudSubscriptionFeatures.OptIn.Changed` | disabled | still disabled, quiet |
| `akd` | Apple ID / iCloud auth | running | running, quiet |
| `bird` / CloudDocs FP | iCloud Drive | running | running, quiet |
| `photolibraryd` | Photos iCloud events in plist triggers | disabled (separate test) | unchanged |
| `com.apple.ind.cloudfeatures` Mach port | owned by FeatureAccessAgent | active | gone with agent |

## Notes

- Heavier than geo/consumer tails (~23 MB) but headless impact was clean on this target.
- Distinct from MDM/remotemanagement and from Photos analysis daemons.
- Re-enable if using iCloud+ feature gates, subscription-dependent system prompts, or debugging CloudSubscriptionFeatures on this Mac.