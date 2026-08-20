# Country / region / regulatory domain — `countryd` (countryd-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `countryd` only                                                |
| Category      | Country / region / regulatory domain disabled                  |
| Risk Level    | **2–3** — geo/regulatory input daemon; headless clean here     |
| Profile       | **keep disabled on coding target without regional compliance** |

## What It Does (за что отвечает)

**System** daemon (`RegulatoryDomain`) — estimates the device's **physical/regulatory country** and maintains a shared cache:

| Input signal | Role |
|--------------|------|
| GPS / Location | Strongest indicator when available |
| WiFi AP country (802.11d) | Local wireless hints |
| Cell MCC (nearby/serving) | Mobile network country codes |
| Geo IP | IP-based country estimate |
| Peer sharing | Nearby Apple device country estimates |

| Output | Consumer |
|--------|----------|
| `/var/db/com.apple.countryd/countryCodeCache.plist` | `geod`, `eligibilityd`, regulatory/geo stacks |
| Mach `com.apple.countryd.update` | Country cache updates |

Per `man countryd`: combines on-device sensors + peer answers into a **CombinedEstimate** country code.

**Not touched in this test:** `geod`, `locationd`, `mobileassetd`, `appstoreagent`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.countryd` | system | `countryd` | `/System/Library/LaunchDaemons/com.apple.countryd.plist` |

**Binary:** `/usr/libexec/countryd`

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `countryd` | ~11 MB |

**Cache before disable:** `countryCodeCache.plist` present; estimates from GeoIP + WiFi AP; Location/Cell empty on this Mac.

## Disable (system only)

```bash
sudo launchctl bootout system/com.apple.countryd 2>/dev/null || true
sudo launchctl disable system/com.apple.countryd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.countryd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **countryd-off**

**Context:** `eligibilityd` already disabled from prior test (`eligibilityd-off`).

**Before:** processes **312**, total RSS **5878 MB**, `countryd` running (~11 MB).

1. Bootout/disable `system/com.apple.countryd` — gone immediately.
2. Reboot — SSH back ~24 s.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `countryd`: **not running**; system disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 countryd/RegulatoryDomain/country code lines; 0 error/fail/retry/denied
   - **Neighbors (untouched) — behavior:**

| Neighbor | Status after reboot | Log noise |
|----------|---------------------|-----------|
| `eligibilityd` | still **disabled**, not running | **none** |
| `geod` | running (×2, ~19 MB each) | **none** |
| `locationd` | running (~29 MB) | **none** |
| `mobileassetd` | running (~35 MB) | **none** |
| `appstoreagent` | running (~48 MB) | **none** |

4. **After metrics:** processes **307**, total RSS **5537 MB** (~11 MB from daemon removed)

**Verdict: keep disabled on coding experimental target** (with `eligibilityd` already off). **Rollback** if needing live regulatory country resolution or fresh country cache updates.

## Exact Breakage Notes (expected, GUI not tested)

| Area | Impact |
|------|--------|
| Country/region resolution | No fresh regulatory country estimates |
| Regulatory country cache | `/var/db/com.apple.countryd/` stops updating |
| Regional feature decisions | `eligibilityd` consumers lose live country input (eligibilityd already disabled here) |
| Storefront/regional Apple services | Possible stale region hints for geo/storefront paths |
| Geo/compliance flows | Wi-Fi regulatory domain, geo compliance paths that read countryd cache |

**Not broken (verified headless):** SSH; `geod`/`locationd`/`mobileassetd`/`appstoreagent` stayed up without retry storms.

## Clients / Who Made Noise After Disable

| Client / neighbor | Noise after disable + reboot |
|-------------------|------------------------------|
| `geod` | running, **quiet** — no countryd error coupling in logs |
| `locationd` | running, **quiet** |
| `mobileassetd` | running, **quiet** |
| `appstoreagent` | running, **quiet** |
| `eligibilityd` | disabled (prior test), **quiet** |
| Other processes | **no** countryd respawn or log storm |

## Notes

- Adjacent to `eligibilityd` in regulatory stack; both now disabled on this target.
- `geod` may still read stale `countryCodeCache.plist` on disk.
- Distinct from `eligibilityd` (policy domains) — countryd is **location/regulatory country estimation** only.
- Re-enable if using region-accurate Apple compliance/storefront/geo flows on this Mac.