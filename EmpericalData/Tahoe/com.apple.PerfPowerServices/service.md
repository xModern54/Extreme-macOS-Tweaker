# Power / Performance Diagnostics

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `PerfPowerServices` + `PerfPowerTelemetryClientRegistrationService` |
| Category      | Power / Performance Diagnostics                                  |
| Risk Level    | 2–3 — disables power/perf diagnostics collection; core power/thermal stack kept |

**Breaks:** power/perf log archives, diagnostics collection  
**Should not break:** charging, sleep, thermal control

## What It Does

Apple **PerfPower / PowerLog diagnostics** layer — not core power management or thermal control:

| Label | Domain | Process | Role |
|-------|--------|---------|------|
| `com.apple.PerfPowerServices` | system | `PerfPowerServices` | Main PerfPower diagnostics daemon (`/usr/libexec/PerfPowerServices`) |
| `com.apple.PerfPowerTelemetryClientRegistrationService` | system (XPC) | `PerfPowerTelemetryClientRegistrationService` | PowerLog telemetry client registration XPC service |

**Explicitly kept (per test plan):**

| Component | Role |
|-----------|------|
| `com.apple.powerd` | Core power management |
| `com.apple.powerexperienced` | Power modes / resource usage / mitigation controllers |
| `com.apple.thermalmonitord` | Thermal monitoring |
| `com.apple.systemstats.analysis` | `systemstats --daemon` |
| `com.apple.logd` / `logd_helper` | Unified logging |
| `ReportCrash` | Crash reporter |

Related prior disables: `powerlogHelperd`, `perfpowermetricd`, analytics hub — see `services/com.apple.usbctelemetryd/service.md`, `services/com.apple.analyticsd/service.md`.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `PerfPowerServices` | running | ~28 MB |
| `PerfPowerTelemetryClientRegistrationService` | running | ~6 MB |
| **Running total** | | **~34 MB** |

## Launchd Labels

| Label | Plist / bundle | Domain |
|-------|----------------|--------|
| `com.apple.PerfPowerServices` | `/System/Library/LaunchDaemons/com.apple.PerfPowerServices.plist` | system |
| `com.apple.PerfPowerTelemetryClientRegistrationService` | `/System/Library/PrivateFrameworks/PowerLog.framework/Versions/A/XPCServices/PerfPowerTelemetryClientRegistrationService.xpc` | system (XPC) |

## Disable

```bash
labels=(
  com.apple.PerfPowerServices
  com.apple.PerfPowerTelemetryClientRegistrationService
)
for label in "${labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

**Post-boot tail (observed):** `PerfPowerTelemetryClientRegistrationService` may still on-demand spawn once at boot via Mach IPC despite `launchctl disable`. If present after reboot, run one extra bootout:

```bash
sudo launchctl bootout system/com.apple.PerfPowerTelemetryClientRegistrationService 2>/dev/null || true
```

`PerfPowerServices` stayed disabled across reboots in testing.

## Rollback

```bash
sudo launchctl enable system/com.apple.PerfPowerServices
sudo launchctl enable system/com.apple.PerfPowerTelemetryClientRegistrationService
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: both processes running (~34 MB RSS).
2. Bootout/disable both — gone immediately.
3. Kept stack still running: `powerd`, `powerexperienced`, `thermalmonitord`, `systemstats`, `logd`, `ReportCrash`.
4. Reboot — SSH back ~18–31 s.
5. Post-reboot: `PerfPowerServices` absent; disable flags intact.
6. **XPC tail:** `PerfPowerTelemetryClientRegistrationService` respawned once at boot (on-demand Mach IPC) despite disable flag; `launchctl bootout` removed it and it stayed gone until next cold boot.
7. **SSH:** OK.
8. **Battery/AC:** `pmset -g batt` shows 80–84%, AC attached, charging/present.
9. **Sleep/wake:** scheduled `pmset schedule wake` + `pmset sleepnow` (~30 s); SSH returned after wake; power status OK.
10. **CPU:** `powerd` ~0%, `logd` ~0.5% — no elevated load.
11. **Logging:** `log show` OK.
12. **Log storm:** 0 lines for PerfPower/PowerLog/perfpower in boot and post-wake windows.

**Verdict: cautious disable validated on coding experimental target — charging, sleep/wake, and thermal/power core preserved.**

## Expected Breakage

- PerfPower diagnostics and PowerLog archive collection.
- PowerLog telemetry client registration path.
- Internal Apple power/performance diagnostic tooling that depends on `PerfPowerServices`.

**Not broken (verified):** SSH, battery/AC/charge reporting, sleep/wake cycle, `powerd`, `powerexperienced`, `thermalmonitord`, `systemstats`, unified logging, `ReportCrash`.

## Notes

- Cautious wave — explicitly did **not** disable `powerd`, `thermalmonitord`, or `systemstats`.
- `com.apple.PerfPowerServicesExtended` exists but was not in scope (still enabled, idle).
- XPC on-demand behavior for telemetry registration is the main unresolved tail; consider post-reboot bootout in future tweaker health-check until a stronger disable method is found.
- Re-enable both labels if using Apple's power diagnostics / `powermetrics` archive workflows.