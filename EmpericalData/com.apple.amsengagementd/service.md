# App Store — Ads / Engagement Layer (narrow disable)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | AMS ads/engagement only — **not** full App Store daemon removal |
| Category      | `analytics_telemetry` / ads                                    |
| Risk Level    | 1–2 — narrow slice; core App Store kept enabled                |

## What It Does

Apple Media Services **ads and engagement** plumbing, separate from core App Store install/update path:

| Label | Process | Role |
|-------|---------|------|
| `com.apple.amsengagementd` | `amsengagementd` | AMS UI engagement / storefront campaigns |
| `com.apple.ap.promotedcontentd` | `promotedcontentd` | Promoted content / Apple Ads delivery |
| `com.apple.ap.adprivacyd` | `adprivacyd` | Ad privacy / attribution tokens |

**Kept enabled (per test plan):**

| Label | Role |
|-------|------|
| `com.apple.appstoreagent` | App Store daemon — installs, updates, catalog |
| `com.apple.amsaccountsd` | AMS account layer |
| `com.apple.fairplaydeviceidentityd` | FairPlay DRM identity (demand-started) |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `amsengagementd` | ~22 MB |
| `promotedcontentd` | ~22 MB |
| `adprivacyd` | ~16 MB |
| **Total** | **~60 MB** |

## Launchd Labels

All three are gui/502 LaunchAgents under `/System/Library/LaunchAgents/`.

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.amsengagementd
  com.apple.ap.promotedcontentd
  com.apple.ap.adprivacyd
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.amsengagementd com.apple.ap.promotedcontentd com.apple.ap.adprivacyd; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: all three ads processes running (~60 MB); `appstoreagent`, `amsaccountsd`, `fairplaydeviceidentityd` running.
2. Bootout/disable — ads processes gone; kept labels still running.
3. 30-second delayed check — ads processes did not return.
4. Reboot — SSH back ~22 seconds.
5. Post-reboot: ads layer still absent; disable flags intact.
6. **App Store opens:** `open -a "App Store"` → `App Store` process running (~210–257 MB RSS).
7. **Updates list:** `softwareupdate --list` returned CLT + macOS updates; `open macappstore://showUpdates` opened App Store updates flow.
8. **Free app catalog page:** `open macappstore://itunes.apple.com/app/id640199958` — App Store + `appstoreagent` active, no errors in 2m log window.
9. **Log storm check:** 0 boot-time log lines matching amsengagement/promotedcontent/adprivacy; 60s delayed — no processes returned, no error/retry loops.
10. `appstoreagent` RSS increased on App Store launch (normal demand activity).
11. `fairplaydeviceidentityd` idle until needed (label still enabled).

**Verdict: narrow ads/engagement disable is safe; core App Store path works on experimental target.**

### User-confirmed — cumulative stack (2026-06-20)

Validated on target **with full current disable stack** (notifications A+B, MDM/RM, `feedbackd`, ads layer, and all prior session disables — ~121 gui + ~35 system labels). Interactive GUI session:

- **Apple Account:** sign-in and account UI work; account infrastructure not broken.
- **App Store:** app opens and operates normally.
- **App downloads:** installing apps from App Store works (user-verified end-to-end).

**Conclusion:** current tweaks so far do **not** fully break App Store / Apple Account infrastructure. Ads/engagement removal is a safe narrow slice; core path (`appstoreagent`, `amsaccountsd`, `appleaccountd`, account sign-in) remains functional.

## Expected Breakage

- Apple Ads / promoted content / engagement campaigns in App Store and AMS surfaces.
- Ad privacy / attribution plumbing for promoted content.

**Not broken (verified):** Apple Account sign-in, App Store app launch, App Store app install/download, update listing (`softwareupdate --list`), `appstoreagent` / `amsaccountsd` operation.

## Notes

- Intentional partial App Store stack trim — do not disable `appstoreagent` in same group.
- Full App Store daemon removal is a separate, higher-risk experiment.