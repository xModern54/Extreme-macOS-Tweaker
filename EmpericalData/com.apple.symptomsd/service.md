# Network Symptoms / Wi-Fi Analytics

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `symptomsd` + `symptomsd-diag` + `wifianalyticsd`              |
| Category      | `analytics_telemetry` / network diagnostics                    |
| Risk Level    | 2 — network symptom analytics; core networking kept enabled     |

## What It Does

Apple network **telemetry and symptom collection** — not core packet forwarding:

| Label | Process | Role |
|-------|---------|------|
| `com.apple.symptomsd` | `symptomsd` | Network symptom analytics hub (`GroupName` `_networkd`) |
| `com.apple.symptomsd-diag` | `symptomsd-diag` | Symptom diagnostics collection daemon |
| `com.apple.wifianalyticsd` | `wifianalyticsd` | Wi-Fi-specific analytics and device store |

**Explicitly kept (per test plan):** `networkd`, `configd`, `mDNSResponder`, `airportd`, `WiFiAgent`, `nehelper`, `neagent`, `analyticsd`, `logd`.

`com.apple.symptomsd-diag.agent` (gui) disabled later in input/audio/diagnostics wave — see `services/com.apple.inputanalyticsd/service.md`.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `symptomsd` | ~20 MB |
| `symptomsd-diag` | ~13 MB |
| `wifianalyticsd` | ~13 MB |
| **Total** | **~46 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.symptomsd` | `/System/Library/LaunchDaemons/com.apple.symptomsd.plist` | system |
| `com.apple.symptomsd-diag` | `/System/Library/LaunchDaemons/com.apple.symptomsd-diag.plist` | system |
| `com.apple.wifianalyticsd` | `/System/Library/LaunchDaemons/com.apple.wifianalyticsd.plist` | system |

## Disable

```bash
labels=(
  com.apple.symptomsd
  com.apple.symptomsd-diag
  com.apple.wifianalyticsd
)
for label in "${labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
for label in com.apple.symptomsd com.apple.symptomsd-diag com.apple.wifianalyticsd; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all three running (~46 MB RSS total).
2. Bootout/disable — processes disappeared immediately.
3. Kept stack still running: `WiFiAgent`, `airportd`, `mDNSResponder`, `configd`, `nehelper`, `analyticsd`, `logd`.
4. Reboot — SSH back ~25 seconds.
5. Post-reboot: no `symptomsd` / `symptomsd-diag` / `wifianalyticsd` processes; disable flags intact.
6. **SSH:** OK.
7. **Wi-Fi / DNS:** gateway `192.168.1.1` via `en0`, DNS resolver reachable.
8. **curl https://apple.com:** HTTP 301 in ~0.19s (redirect, connectivity OK).
9. **Log storm:** 0 boot-time log lines for symptomsd/wifianalyticsd; no error/retry loops in 5m window.

**Verdict: safe to disable on coding experimental target — network connectivity preserved.**

## Expected Breakage

- Network symptom reporting and Wi-Fi analytics uploads to Apple.
- Internal network quality / symptom diagnostics used by Apple ecosystem features.

No observed impact on SSH, Wi-Fi association, DNS, or HTTP egress.

## Notes

- First slice of planned analytics/telemetry reduction phase.
- `symptomsd` shares `_networkd` group name but is analytics, not `com.apple.networkd` packet path.
- `analyticsd` intentionally left enabled for a later wave.