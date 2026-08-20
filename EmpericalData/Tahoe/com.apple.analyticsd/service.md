# Analytics Hub / Reporting Layer

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `analyticsd` + `analyticsagent` + `osanalyticshelper` + `rtcreportingd` + `geoanalyticsd` + `metrickitd` |
| Category      | `analytics_telemetry` / diagnostics reporting                    |
| Risk Level    | 2 — Apple analytics upload hub and reporting agents; core logging/crash/symbolication kept |

## What It Does

Core Apple **analytics and diagnostic reporting** stack — not unified logging or crash symbolication:

| Label | Domain | Process | Role |
|-------|--------|---------|------|
| `com.apple.analyticsd` | system | `analyticsd` | CoreAnalytics hub (`CoreAnalyticsMessenger`); central telemetry ingest |
| `com.apple.analyticsagent` | gui | `analyticsagent` | Per-user analytics agent (GMS availability notify trigger) |
| `com.apple.osanalytics.osanalyticshelper` | system | `osanalyticshelper` | OS analytics helper: diagnostic monitor, log transfer, job quiescence |
| `com.apple.rtcreportingd` | system | `rtcreportingd` | RTC (Real-Time Clock / crash telemetry channel) reporting daemon |
| `com.apple.geoanalyticsd` | gui | `geoanalyticsd` | Geo/location usage analytics (on-demand / periodic bg task) |
| `com.apple.metrickitd` | gui | `metrickitd` | MetricKit daemon and source XPC endpoints |

**Explicitly kept (per test plan):**

| Component | Role |
|-----------|------|
| `com.apple.logd` / `logd_helper` | Unified logging pipeline |
| `syslogd` | Legacy syslog bridge |
| `ReportCrash` | User crash reporter |
| `coresymbolicationd` | Crash log symbolication |
| `com.apple.PerfPowerServices` | Power/performance services (deferred) |
| `com.apple.systemstats.analysis` | `systemstats --daemon` analysis service |

Related prior disables: `symptomsd`, `wifianalyticsd`, `inputanalyticsd`, `audioanalyticsd`, `ecosystemd` — see respective service cards.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `analyticsd` | running | ~26 MB |
| `osanalyticshelper` | running | ~10 MB |
| `rtcreportingd` | idle at capture | 0 |
| `analyticsagent` | idle at capture | 0 |
| `geoanalyticsd` | idle at capture | 0 |
| `metrickitd` | idle at capture | 0 |
| **Running total** | | **~36 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.analyticsd` | `/System/Library/LaunchDaemons/com.apple.analyticsd.plist` | system |
| `com.apple.osanalytics.osanalyticshelper` | `/System/Library/LaunchDaemons/com.apple.osanalytics.osanalyticshelper.plist` | system |
| `com.apple.rtcreportingd` | `/System/Library/LaunchDaemons/com.apple.rtcreportingd.plist` | system |
| `com.apple.analyticsagent` | `/System/Library/LaunchAgents/com.apple.analyticsagent.plist` | gui |
| `com.apple.geoanalyticsd` | `/System/Library/LaunchAgents/com.apple.geoanalyticsd.plist` | gui |
| `com.apple.metrickitd` | `/System/Library/LaunchAgents/com.apple.metrickitd.plist` | gui |

## Disable

```bash
uid=$(id -u)
labels_system=(
  com.apple.analyticsd
  com.apple.osanalytics.osanalyticshelper
  com.apple.rtcreportingd
)
labels_gui=(
  com.apple.analyticsagent
  com.apple.geoanalyticsd
  com.apple.metrickitd
)
for label in "${labels_system[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
for label in "${labels_gui[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.analyticsd com.apple.osanalytics.osanalyticshelper com.apple.rtcreportingd; do
  sudo launchctl enable "system/$label"
done
for label in com.apple.analyticsagent com.apple.geoanalyticsd com.apple.metrickitd; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `analyticsd` + `osanalyticshelper` running (~36 MB); four other labels enabled (idle).
2. Bootout/disable all six — `analyticsd` and `osanalyticshelper` gone immediately.
3. Kept stack still running: `logd`, `logd_helper`, `syslogd`, `ReportCrash`, `coresymbolicationd`, `PerfPowerServices`, `systemstats`.
4. Reboot — SSH back ~18 seconds.
5. Post-reboot: no disabled-group processes; all six disable flags intact.
6. **SSH:** OK.
7. **Logging:** `log show --last 1m` OK (Console pipeline works).
8. **Apps:** Calculator and TextEdit launched normally.
9. **Log storm:** 0 boot-time lines for analyticsd/osanalytics/rtcreporting/metrickit/geoanalytics; no related error/retry loops in 5m window.
10. **ReportCrash:** process present (~4 MB); 0 boot-time log lines (no spam).

**Verdict: safe to disable on coding experimental target — logging and crash reporting preserved.**

## Expected Breakage

- Apple CoreAnalytics telemetry uploads and on-device analytics aggregation.
- OS analytics diagnostic monitor and log-transfer helper path.
- RTC reporting channel.
- Geo usage analytics and MetricKit collection/delivery.
- Per-user `analyticsagent` GMS-triggered collection.

**Not broken (verified):** SSH, unified logging (`logd`/`log show`), native app launch, `ReportCrash` presence, `coresymbolicationd`, `PerfPowerServices`, `systemstats`.

## Notes

- Major analytics hub wave — removes `analyticsd` after earlier peripheral telemetry cuts.
- `biometrickitd` is a separate label (`com.apple.biometrickitd`) and was **not** disabled.
- `PerfPowerServices` and `systemstats.analysis` intentionally deferred to a later wave.
- Re-enable `analyticsd` + `osanalytics.osanalyticshelper` if Apple diagnostic tooling or sysdiagnose analytics paths are needed.