# Idle Telemetry / Diagnostics Tails

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `usbctelemetryd` + `powerlogHelperd` + `perfpowermetricd` + InstallerDiagnostics (`installerdiagd`, `installerdiagwatcher`) |
| Category      | `analytics_telemetry` / power/USB/installer diagnostics         |
| Risk Level    | 1 — idle on-demand daemons; core power management and PerfPower stack kept |

## What It Does

Remaining **idle telemetry and installer diagnostic** launchd jobs — not core power management or active PerfPower services:

| Label | Domain | Process | Role |
|-------|--------|---------|------|
| `com.apple.usbctelemetryd` | system | `usbctelemetryd` | USB-C port telemetry (daily calendar trigger) |
| `com.apple.powerlogHelperd` | system | `powerlogHelperd` | PowerLog helper XPC (`powerlogHelperd.XPCService.xpc`) |
| `com.apple.perfpowermetricd` | system | `perfpowermetricd` | PerfPower metric monitor XPC (`PerfPowerMetricMonitor.xpc`) |
| `com.apple.InstallerDiagnostics.installerdiagd` | system | `installerdiagd` | macOS Installer diagnostics daemon |
| `com.apple.InstallerDiagnostics.installerdiagwatcher` | system | `installerdiagwatcher` | NVRAM-triggered installer diag watcher |

**Not present on target (macOS 26.4.1):** `com.apple.InstallerDiagnostics.installerdiagcontroller` — no plist or launchd label found.

**Explicitly kept (per test plan):**

| Component | Role |
|-----------|------|
| `com.apple.PerfPowerServices` | Active power/performance services |
| `com.apple.PerfPowerTelemetryClientRegistrationService` | PowerLog telemetry client registration XPC |
| `com.apple.powerd` | Core power management |
| `com.apple.thermalmonitord` | Thermal monitoring |
| `com.apple.systemstats.analysis` | `systemstats --daemon` |
| `com.apple.logd` / `logd_helper` | Unified logging |
| `ReportCrash` | Crash reporter |

Related prior disables: analytics hub (`analyticsd` wave), symptoms/input/ecosystem telemetry — see respective service cards.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| All five labels | idle at capture | 0 |
| **Running total** | | **0** |

All were enabled but not resident in process list at disable time.

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.usbctelemetryd` | `/System/Library/LaunchDaemons/com.apple.usbctelemetryd.plist` | system |
| `com.apple.powerlogHelperd` | `/System/Library/LaunchDaemons/com.apple.powerlogHelperd.plist` | system |
| `com.apple.perfpowermetricd` | `/System/Library/LaunchDaemons/com.apple.perfpowermetricd.plist` | system |
| `com.apple.InstallerDiagnostics.installerdiagd` | `/System/Library/LaunchDaemons/com.apple.InstallerDiagnostics.installerdiagd.plist` | system |
| `com.apple.InstallerDiagnostics.installerdiagwatcher` | `/System/Library/LaunchDaemons/com.apple.InstallerDiagnostics.installerdiagwatcher.plist` | system |

## Disable

```bash
labels=(
  com.apple.usbctelemetryd
  com.apple.powerlogHelperd
  com.apple.perfpowermetricd
  com.apple.InstallerDiagnostics.installerdiagd
  com.apple.InstallerDiagnostics.installerdiagwatcher
)
for label in "${labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
for label in com.apple.usbctelemetryd com.apple.powerlogHelperd com.apple.perfpowermetricd com.apple.InstallerDiagnostics.installerdiagd com.apple.InstallerDiagnostics.installerdiagwatcher; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all five labels enabled; none running (idle, 0 RSS).
2. `installerdiagcontroller` — not found on this macOS build; skipped.
3. Bootout/disable all five — no target processes (already idle).
4. Kept stack still running: `PerfPowerServices`, `PerfPowerTelemetryClientRegistrationService`, `powerd`, `thermalmonitord`, `systemstats`, `logd`, `ReportCrash`.
5. Reboot — SSH back ~20 seconds.
6. Post-reboot: no disabled-group processes; all five disable flags intact.
7. **SSH:** OK.
8. **Power/battery:** `pmset -g batt` shows 80%, AC attached, charging; battery present.
9. **Logging:** `log show --last 1m` OK.
10. **Log storm:** 0 boot-time lines for usbctelemetry/powerlogHelper/perfpowermetric/installerdiag; no error/retry loops.

**Verdict: safe to disable on coding experimental target — power display and core PerfPower stack preserved.**

## Expected Breakage & Critical Side Effects

- USB-C telemetry uploads (daily collection).
- **Apple Silicon USB Accessory Authorization Prompt Suppression**: Disabling `com.apple.usbnotificationagent` / notification daemons prevents the system alert *"Allow accessory to connect?"* from popping up when plugging in a new USB flash drive, iPad, or iPhone. On default macOS security settings (*"Ask for new accessories"*), new USB devices will fail to mount because the approval UI prompt is suppressed!
  - **Required Configuration Fix**: In macOS **System Settings -> Privacy & Security -> "Allow accessories to connect"**, set the policy to **"Automatically when unlocked"** (или *"Всегда"*). New USB flash drives and iPads will then mount immediately without requiring the notification prompt!

- PowerLog helper and PerfPower metric monitor on-demand paths.
- Installer diagnostics collection during macOS Installer failures.

**Not broken (verified):** SSH, battery/charge reporting via `pmset`, unified logging, `PerfPowerServices`, `powerd`, `thermalmonitord`, `systemstats`.

## Notes

- Idle-tail cleanup after analytics hub wave; no immediate RSS savings observed.
- `PerfPowerServices` and `PerfPowerTelemetryClientRegistrationService` remain for a potential later PerfPower wave.
- Re-enable InstallerDiagnostics labels if debugging macOS Installer failures via Apple's diag tooling.