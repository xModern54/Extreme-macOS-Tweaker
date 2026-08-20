# Apple Trial — A/B Experiments / Feature Flags

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Trial (`triald` + `triald_system` + `TrialArchivingService` XPC) |
| Category      | `analytics_telemetry` / experiment infrastructure              |
| Risk Level    | 2 — disables A/B experiment plumbing; not boot-critical        |

## What It Does

Apple **Trial** is internal infrastructure for A/B tests, feature flags, and experiment rollouts across macOS — not a "trial software" feature.

| Component | Role |
|-----------|------|
| **triald** | Per-user agent: fetch/cache experiment treatments, namespace management, push (`aps.triald`) |
| **triald_system** | System daemon: system-wide namespaces, maintenance, CloudKit experiment sync |
| **TrialArchivingService** | XPC helper spawned by `triald` — archives and maintains Trial treatment data |

209 namespace descriptors exist under `/System/Library/Trial/NamespaceDescriptors/` covering ads, power tuning, intelligence, Siri, core OS experiments, etc.

Not required for SSH, coding tools, compilers, or Git.

## Observed Cost (before disable)

| Process                  | Domain | RSS     |
|--------------------------|--------|---------|
| `triald`                 | gui    | ~19 MB  |
| `triald_system`          | system | ~16 MB  |
| `TrialArchivingService`  | XPC    | ~16 MB  |
| **Total RSS**            |        | **~52 MB** |

Disk caches (not RSS): `~/Library/Trial` ~28 MB, `/Library/Trial` ~33 MB.

## Launchd Labels

| Label                    | Plist                                                         | Domain |
|--------------------------|---------------------------------------------------------------|--------|
| `com.apple.triald`       | `/System/Library/LaunchAgents/com.apple.triald.plist`         | gui    |
| `com.apple.triald.system` | `/System/Library/LaunchDaemons/com.apple.triald.system.plist` | system |

### triald (gui) endpoints

```text
com.apple.triald.internal
com.apple.trial.status
com.apple.aps.triald
com.apple.triald.namespace-management
com.apple.triald.cache-delete
```

### triald_system endpoints

```text
com.apple.triald.system.internal
com.apple.trial.system.status
com.apple.aps.system.triald
com.apple.triald.system.namespace-management
com.apple.triald.system.cache-delete
com.apple.triald.system.from-agent
```

### TrialArchivingService

```text
Bundle: com.apple.trial.TrialArchivingService
Path: .../TrialServer.framework/.../TrialArchivingService.xpc
No launchd label — XPC child of triald (domain pid/<triald-pid>)
```

### Periodic activity (both daemons)

```text
fetch-experiments     — ~24h interval, requires network
maintenance           — ~24h interval
cellular / wifi client triggers
post-upgrade fetch tasks
```

## Known live clients (before disable)

Processes with `com.apple.trial.client` entitlement:

```text
analyticsd
BiomeAgent
adprivacyd
promotedcontentd
```

Already-disabled clients included `ospredictiond`, generative AI stack, Siri/parsecd.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.triald" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.triald"
sudo launchctl bootout system/com.apple.triald.system 2>/dev/null || true
sudo launchctl disable system/com.apple.triald.system
```

`TrialArchivingService` exits when `triald` is booted out.

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.triald"
sudo launchctl enable system/com.apple.triald.system
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `triald` ~19 MB, `triald_system` ~16 MB, `TrialArchivingService` ~16 MB (~52 MB total).
2. Bootout gui `triald` and system `triald_system` — all 3 processes disappeared immediately.
3. No errors in logs after bootout.
4. 30-second delayed check — none returned.
5. Disabled both labels — confirmed in `launchctl print-disabled`.
6. Rebooted target; SSH back in ~23 seconds.
7. Post-reboot health: SSH, login, gateway, memory pressure OK.
8. No triald/TrialArchiving processes after reboot.
9. `BiomeAgent`, `analyticsd`, `promotedcontentd` still running — no obvious crash loops.
10. No triald-related error log entries during boot.
11. Process count: 330.

**Verdict: safe to disable on coding experimental target.** ~52 MB RSS saved; reduces periodic experiment fetch network activity.

## Expected Breakage

- A/B experiment buckets and feature-flag rollouts for system and apps.
- Trial-driven ad/analytics experiment assignments (`promotedcontentd`, `adprivacyd`).
- Biome ↔ Trial experiment sync may degrade.
- Push experiment updates via `aps.triald` / `aps.system.triald`.
- Some COREOS_* experiment-driven power/memory tunings may fall back to defaults.

Does not affect SSH, Wi-Fi, boot, or `locationd`.

## Notes

- Disk caches under `~/Library/Trial` and `/Library/Trial` remain after disable; safe to delete manually if reclaiming disk space.
- Separate from the disabled Generative AI stack, but shared Intelligence/Siri Trial namespaces become irrelevant on this target.
- Re-enable before caring about Apple experiment rollouts on this machine.