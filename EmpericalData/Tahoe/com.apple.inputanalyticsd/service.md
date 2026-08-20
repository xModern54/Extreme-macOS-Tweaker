# Input / Audio / Diagnostics Telemetry

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `inputanalyticsd` + `audioanalyticsd` + `diagnosticextensionsd` + `diagnostics_agent` + `symptomsd-diag.agent` |
| Category      | `analytics_telemetry` / diagnostics                            |
| Risk Level    | 2 — telemetry collectors; core audio/logging/symbolication kept |

## What It Does

Peripheral Apple telemetry and diagnostic extension hosts — not core logging or audio playback:

| Label | Domain | Process | Role |
|-------|--------|---------|------|
| `com.apple.inputanalyticsd` | gui | `inputanalyticsd` | Keyboard/input usage analytics |
| `com.apple.audioanalyticsd` | system | `audioanalyticsd` | Audio subsystem analytics |
| `com.apple.diagnosticextensionsd` | gui | `diagnosticextensionsd` | Diagnostic Extensions XPC host |
| `com.apple.diagnostics_agent` | gui | `diagnostics_agent` | Per-user diagnostics collection agent |
| `com.apple.symptomsd-diag.agent` | gui | *(agent)* | GUI companion for `symptomsd-diag` (system already disabled) |

**Kept (per test plan):** `analyticsd`, `logd`, `logd_helper`, `coreaudiod`, `AudioComponentRegistrar`, `coresymbolicationd`, `ReportCrash`.

Related prior disable: `symptomsd`, `symptomsd-diag`, `wifianalyticsd` (system) — see `services/com.apple.symptomsd/service.md`.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `diagnosticextensionsd` | running | ~20 MB |
| `diagnostics_agent` | running | ~11 MB |
| `inputanalyticsd`, `audioanalyticsd`, `symptomsd-diag.agent` | idle at capture | 0 |
| **Running total** | | **~31 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.inputanalyticsd` | LaunchAgents | gui |
| `com.apple.audioanalyticsd` | LaunchDaemons | system |
| `com.apple.diagnosticextensionsd` | LaunchAgents | gui |
| `com.apple.diagnostics_agent` | LaunchAgents | gui |
| `com.apple.symptomsd-diag.agent` | LaunchAgents | gui |

## Disable

```bash
uid=$(id -u)
for label in com.apple.inputanalyticsd com.apple.diagnosticextensionsd com.apple.diagnostics_agent com.apple.symptomsd-diag.agent; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
sudo launchctl bootout system/com.apple.audioanalyticsd 2>/dev/null || true
sudo launchctl disable system/com.apple.audioanalyticsd
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.inputanalyticsd com.apple.diagnosticextensionsd com.apple.diagnostics_agent com.apple.symptomsd-diag.agent; do
  launchctl enable "gui/$uid/$label"
done
sudo launchctl enable system/com.apple.audioanalyticsd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `diagnosticextensionsd` + `diagnostics_agent` running (~31 MB); three other labels enabled (idle).
2. Bootout/disable all five — target processes gone immediately.
3. Kept stack running: `analyticsd`, `logd`, `logd_helper`, `coreaudiod`, `AudioComponentRegistrar`, `coresymbolicationd`, `ReportCrash`.
4. Reboot — SSH back ~19 seconds.
5. Post-reboot: no disabled-group processes; all five disable flags intact.
6. **SSH:** OK.
7. **HID:** IOHID stack present (keyboard/trackpad path alive).
8. **Audio:** `coreaudiod` running; `afplay Glass.aiff` OK.
9. **Logging:** `log show --last 1m` OK (Console pipeline works).
10. **Log storm:** 0 boot-time lines for disabled labels; no error/retry loops in 5m window.

**Verdict: safe to disable on coding experimental target.**

## Expected Breakage

- Input and audio usage analytics uploads.
- Diagnostic Extensions host for system/app diagnostic panels.
- Per-user diagnostics agent collection.
- Symptoms diag GUI agent (system `symptomsd-diag` was already disabled).

**Not broken (verified):** SSH, keyboard/trackpad/mouse HID, audio playback, unified logging, crash reporting (`ReportCrash`), `analyticsd` hub.

## Notes

- Second wave of analytics/telemetry reduction after `symptomsd` / `wifianalyticsd`.
- `analyticsd` deliberately deferred to a later wave.
- Re-enable `diagnosticextensionsd` if using macOS Diagnostic Extensions or sysdiagnose tooling that depends on the host.