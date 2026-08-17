# Photos Core — `photolibraryd` (Photos-core-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `photolibraryd` only (Photos-core-off experiment)              |
| Category      | `photos_media_analysis` / Photos library core                  |
| Risk Level    | 2 — breaks Photos ecosystem; OK for no-Photos coding profile   |
| Profile       | **safe for no-Photos profile**                                 |

**Breaks:** Photos.app, iCloud Photos / MediaStream, Photo picker from Photos library, Photos-specific search/index  
**Should not break:** SSH, GUI login, Finder, generic QuickLook outside Photos Library, screenshots (`replayd`)

**Not the same as disabled `mediaanalysisd` / `photoanalysisd`** — those are ML/analysis slices; `photolibraryd` is the core Photos library daemon (`photos.service`, CPL, Photos CoreSpotlight receivers).

Related prior disables: `com.apple.mediaanalysisd`, `com.apple.photoanalysisd`, Spotlight (`mds`), `com.apple.biomesyncd`.

## What It Does

Per-user **Photos library daemon** — not optional helper:

| Role | Detail |
|------|--------|
| Library API | Mach service `com.apple.photos.service` |
| iCloud Photos | CPL / `cloudphotod` integration triggers |
| Spotlight (Photos) | `com.apple.corespotlight.receiver.photos` (+ search) |
| Maintenance | `dasd` curated-library + periodic tasks |
| Storage | `~/Pictures/Photos Library.photoslibrary`, sandbox container |

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.photolibraryd` | gui | `photolibraryd` | `/System/Library/LaunchAgents/com.apple.photolibraryd.plist` |

**Binary:** `/System/Library/PrivateFrameworks/PhotoLibraryServices.framework/Versions/A/Support/photolibraryd`

**Launch:** LaunchAgent, on-demand via Mach IPC (`immediate reason = ipc (mach)`), `KeepAlive` only on crash.

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `photolibraryd` | ~10 MB |

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.photolibraryd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.photolibraryd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.photolibraryd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **Photos-core-off**

1. Pre-disable: `photolibraryd` running (~10 MB); `mediaanalysisd` / `photoanalysisd` already disabled.
2. Bootout/disable `gui/502/com.apple.photolibraryd` — process gone immediately.
3. Reboot — SSH back; disable flag intact; `photolibraryd` not running.
4. **Photos.app:** **полностью ломается** — не открывается / зависает (user-confirmed, expected breakage).
5. **SSH / GUI login:** OK.
6. **Finder:** OK.
7. **QuickLook** PNG/JPG/PDF вне Photos Library: expected OK on no-Photos profile (generic `ThumbnailsAgent` separate).
8. **Screenshot / `replayd`:** expected OK (protected, not touched).
9. **Log storm:** no retry storm observed for photolibrary/photos/CPL post-disable.

**Verdict: validated disable for no-Photos coding target — keep disabled if Photos.app is not needed.**

## Expected Breakage

- **Photos.app** — полный отказ (подтверждено на target).
- iCloud Photos upload/sync, MediaStream, Photo picker из Photos library.
- Photos-specific search/index (`corespotlight.receiver.photos` hosted here).
- Curated library / CPL background maintenance.

**Not broken (target profile):** SSH, Finder, generic file QuickLook, screenshots, coding toolchain.

## Notes

- Отдельный эксперимент от `mediaanalysisd` wave — не объединять в один disable batch без явного intent.
- На target есть `~/Pictures/Photos Library.photoslibrary` (~8 MB) — библиотека остаётся на диске, но без daemon недоступна.
- Idle siblings for future bundle: `cloudphotod`, `mediastream.mstreamd` (0 RSS at capture).
- Re-enable before any Photos/iCloud Photos workflow on this Mac.