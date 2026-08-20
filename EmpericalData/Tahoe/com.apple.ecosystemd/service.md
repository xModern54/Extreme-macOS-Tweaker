# Ecosystem Analytics / Rosetta Warning Layer

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `ecosystemd` + `ecosystemanalyticsd` + `ecosystemagent`        |
| Category      | `analytics_telemetry` / Rosetta deprecation warnings             |
| Risk Level    | 2 — ecosystem telemetry and unsupported-app warnings; Rosetta runtime kept |

## What It Does

Apple **Ecosystem** framework — tracks Rosetta/Intel app usage, unsupported-app lists, deprecation warnings, and related analytics. Not the Rosetta translation runtime itself.

| Label | Domain | Process | Role |
|-------|--------|---------|------|
| `com.apple.ecosystemd` | system | `ecosystemd` | Daemon hub: Rosetta usage tracking, unsupported-app DB, deprecation warnings, process reporter, catch-up notifications |
| `com.apple.ecosystemanalyticsd` | system | `ecosystemanalyticsd` | Periodic Rosetta/runtime analysis telemetry (weekly `xpc.activity`) |
| `com.apple.ecosystemagent` | gui | `ecosystemagent` | Per-user agent: unsupported-app list, ecosystem notifications (UserNotifications delegate) |

**Important XPC/Mach endpoints (ecosystemd):**

- `com.apple.ecosystem.rosetta`
- `com.apple.ecosystem.daemon.supportedrosettausage`
- `com.apple.ecosystem.daemon.unsupported-apps`
- `com.apple.ecosystem.deprecationwarning`
- `com.apple.ecosystem.processreporter`
- `com.apple.ecosystem.database`
- `com.apple.ecosystem.notifications`

**Explicitly kept (per test plan):**

| Label | Role |
|-------|------|
| `com.apple.oahd` | Rosetta daemon (`/usr/libexec/rosetta/oahd`) — actual x86_64 translation |
| `com.apple.oahd-root-helper` | Rosetta root helper |
| `com.apple.rosetta` | Rosetta install/update service |
| `com.apple.analyticsd` | Core analytics hub (deferred to later wave) |
| `com.apple.logd` | Unified logging |

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `ecosystemd` | running | ~14 MB |
| `ecosystemanalyticsd` | running | ~12 MB |
| `ecosystemagent` | idle at capture | 0 |
| **Running total** | | **~26 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.ecosystemd` | `/System/Library/LaunchDaemons/com.apple.ecosystemd.plist` | system |
| `com.apple.ecosystemanalyticsd` | `/System/Library/LaunchDaemons/com.apple.ecosystemanalyticsd.plist` | system |
| `com.apple.ecosystemagent` | `/System/Library/LaunchAgents/com.apple.ecosystemagent.plist` | gui |

## Disable

```bash
uid=$(id -u)
labels_system=(
  com.apple.ecosystemd
  com.apple.ecosystemanalyticsd
)
for label in "${labels_system[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
launchctl bootout "gui/$uid/com.apple.ecosystemagent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ecosystemagent"
```

## Rollback

```bash
uid=$(id -u)
sudo launchctl enable system/com.apple.ecosystemd
sudo launchctl enable system/com.apple.ecosystemanalyticsd
launchctl enable "gui/$uid/com.apple.ecosystemagent"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `ecosystemd` + `ecosystemanalyticsd` running (~26 MB); `ecosystemagent` enabled (idle).
2. Bootout/disable all three — target processes gone immediately.
3. Kept stack still running: `oahd`, `analyticsd`, `logd`, `logd_helper`.
4. Reboot — SSH back quickly (~19–41 s depending on check).
5. Post-reboot: no `ecosystemd` / `ecosystemanalyticsd` / `ecosystemagent` processes; all three disable flags intact.
6. **SSH:** OK.
7. **Rosetta:** `arch -x86_64 /usr/bin/true` OK; `arch -x86_64 /usr/bin/uname -m` → `x86_64`; `oahd` running (~3 MB).
8. **Apps:** Calculator and TextEdit launched normally.
9. **Log storm:** 0 boot-time log lines for ecosystem/ecosystemanalytics/ecosystemagent; no error/retry loops.

**Verdict: safe to disable on coding experimental target — Rosetta translation preserved.**

## Expected Breakage

- Rosetta deprecation / unsupported-app warning notifications.
- Ecosystem telemetry about Intel/Rosetta app usage and runtime analysis uploads.
- Per-user unsupported-application list and ecosystem notification delegate.

**Not broken (verified):** SSH, native app launch, Rosetta x86_64 execution via `oahd`, `analyticsd` hub, unified logging.

## Notes

- Third analytics/telemetry slice after `symptomsd` / `wifianalyticsd` and input/audio/diagnostics wave.
- Disabling this removes the **warning/telemetry layer**, not Rosetta itself — `oahd` remains the translation path.
- `analyticsd` deliberately left enabled for a later wave.
- If running Intel-only apps that relied on ecosystem deprecation prompts, re-enable `ecosystemagent` + `ecosystemd`.