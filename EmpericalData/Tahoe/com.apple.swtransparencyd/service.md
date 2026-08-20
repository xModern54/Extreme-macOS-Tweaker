# Software Transparency (swtransparencyd) — Disabled

## In Plain Terms

**`swtransparencyd`** — фоновый «проверяльщик» установленных приложений: валидность подписи/нотаризации Apple и отчёты в **CloudTelemetry**. Для coding-машины без заботы о consumer-телеметрии — лишний ~12 MB RAM + поднятый `CloudTelemetryService` + суточные сетевые BG-задачи. Gatekeeper (`syspolicyd`) живёт отдельно.

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | Software Transparency + CloudTelemetry client                |
| Category      | `analytics_telemetry` / `auth_security`                      |
| Risk Level    | 2 — transparency checks/telemetry reduced; Gatekeeper intact   |
| Status        | **Disabled** on target — headless PASS (2026-06-29)          |

## What It Does

Per-user LaunchAgent for **Software Transparency**:

- Verifies installed apps against Apple **notarization / staple** expectations
- Spawns **`CloudTelemetryService.xpc`** on Mach IPC to buffer telemetry events
- Runs daily background tasks (`24h`, `milestone-refresh`) requiring **network**
- Maintains local cache under `~/Library/Caches/com.apple.CloudTelemetry/` (~2.7 MB on target)

On the target with **analytics stack disabled** (`analyticsd`, `osanalytics.osanalyticshelper`, etc.), `CloudTelemetryService` could not flush events and often stayed resident (~12 MB) after login.

**Not the same as:** `syspolicyd` (Gatekeeper) — still enabled; may spawn its own root `CloudTelemetryService` on security events.

## Observed Cost (before disable)

| Component | RSS | Notes |
|-----------|-----|-------|
| `swtransparencyd` | ~12.5 MB | always on after login |
| `CloudTelemetryService` (user) | ~12 MB | spawned by swtransparencyd, stuck when analytics off |
| Disk cache | ~2.7 MB | `~/Library/Caches/com.apple.CloudTelemetry/` |
| CPU | 0% idle | burst at login only |

**Combined savings:** ~24 MB RAM from user transparency + telemetry pair.

## Launchd Labels

| Label | Domain | Plist | Binary |
|-------|--------|-------|--------|
| `com.apple.swtransparencyd` | gui | `/System/Library/LaunchAgents/com.apple.swtransparencyd.plist` | `/usr/libexec/swtransparencyd` |

**Spawned XPC (no launchd label):** `com.apple.CloudTelemetryService.xpc` — on-demand from clients.

**Related clients (not disabled):**

| Label / process | Role |
|-----------------|------|
| `syspolicyd` | Gatekeeper; may spawn root `CloudTelemetryService` (`XPBehavioralDetection`) |
| `com.apple.analyticsd` | Already disabled on target |
| `com.apple.osanalytics.osanalyticshelper` | Already disabled on target |

## Disable

```bash
uid=$(id -u)
label=com.apple.swtransparencyd

launchctl bootout "gui/$uid/$label" 2>/dev/null || true
launchctl disable "gui/$uid/$label"
```

User `CloudTelemetryService` process should exit with the client; kill manually if a stale instance remains:

```bash
pkill -f "CloudTelemetryService"  # only if still visible for uid 502
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.swtransparencyd"
sudo shutdown -r now
```

## Test Result

**2026-06-29 — swtransparencyd-off**

| Check | Result |
|-------|--------|
| Immediate exit | PASS — `swtransparencyd` + user `CloudTelemetryService` gone |
| `launchctl print-disabled` | PASS |
| Reboot persistence | PASS — neither process returned at +17s |
| SSH | PASS |
| Wi‑Fi / default route / DNS (en0) | PASS |
| Unified logs | PASS — quiet since boot |
| Root `CloudTelemetryService` | Not present immediately post-boot (may appear later from `syspolicyd`) |

**GUI:** not yet confirmed by user.

## Expected Breakage

- Background **Software Transparency** checks for installed apps reduced
- User-level **CloudTelemetry** events from this client stop
- Daily `swtransparencyd` network maintenance tasks will not run
- App installs still go through **Gatekeeper / syspolicyd** at run time

Should **not** affect: SSH, Git, compilers, normal app launch for already-trusted software.

## Notes

- Optional disk cleanup: `rm -rf ~/Library/Caches/com.apple.CloudTelemetry`
- For fuller telemetry trim, analytics labels are already disabled; root `CloudTelemetryService` from `syspolicyd` is a separate tail.
- Future tweaker question: *Do you want Software Transparency background checks and related telemetry?*