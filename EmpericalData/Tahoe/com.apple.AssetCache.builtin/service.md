# Content Caching — full AssetCache stack (assetcache-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Apple **Content Caching** — complete stack (6 labels)          |
| Category      | `networking` — optional LAN/CDN cache layer (was inactive)     |
| Risk Level    | **1** — caching never activated on target (0 KB)               |
| Profile       | **keep disabled** on coding-only target                        |

Single feature: **Content Caching** in System Settings → Sharing. All labels below are one stack — disable as a group.

## What It Does

| Label | Domain | Role |
|-------|--------|------|
| `com.apple.AssetCacheLocatorService` | `gui/<uid>` (`-a`) | Client: find LAN/localhost cache servers for downloads |
| `com.apple.AssetCacheLocatorService` | `system` (`-d`) | System locator (`_assetcache`) |
| `com.apple.AssetCache.builtin` | `system` | Content Caching **server** (`/usr/libexec/AssetCache/AssetCache`) |
| `com.apple.AssetCacheTetheratorService` | `system` | USB tethered iOS content caching |
| `com.apple.AssetCacheManagerService` | `system` | **Control plane**: activate/deactivate, status, flush, orchestrate workers |
| `com.apple.AssetCache.agent` | `gui/<uid>` | UI alerts for caching (`AssetCacheAgent`) |

**Not Mac App Store install path.** `appstoreagent` may use locator when enabled; falls back to direct Apple CDN. `softwareupdate` / `mobileassetd` unaffected when caching off.

Pre-disable: **Activated=false**, **CacheUsed=0 KB**, no `.activated` file.

## Observed Cost (when active on target)

| Process | RSS |
|---------|-----|
| Locator `-a` + `-d` | ~28 MB |
| `AssetCache.builtin` | ~12 MB |
| `AssetCacheTetheratorService` | ~8 MB |
| `AssetCacheManagerService` | ~8 MB |
| `AssetCache.agent` | 0 (not running) |
| **Full stack** | **~56 MB** when all workers + manager up |

## Disable (full group)

```bash
uid=$(id -u)
# gui
launchctl bootout "gui/$uid/com.apple.AssetCacheLocatorService" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AssetCacheLocatorService"
launchctl bootout "gui/$uid/com.apple.AssetCache.agent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AssetCache.agent"
# system
for label in com.apple.AssetCacheLocatorService com.apple.AssetCache.builtin \
  com.apple.AssetCacheTetheratorService com.apple.AssetCacheManagerService; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.AssetCacheLocatorService"
launchctl enable "gui/$uid/com.apple.AssetCache.agent"
for label in com.apple.AssetCacheLocatorService com.apple.AssetCache.builtin \
  com.apple.AssetCacheTetheratorService com.apple.AssetCacheManagerService; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

### Phase 1 — workers only (4 labels)

Disabled locator (gui+system), builtin, tetherator. ManagerService respawned on demand (~7 MB). App Store + `softwareupdate` OK headless.

### Phase 2 — full stack (6 labels)

Added `AssetCacheManagerService` + `AssetCache.agent` disable + clean reboot.

1. All six disable flags intact.
2. SSH, Wi‑Fi/route OK.
3. **`pgrep AssetCache` → NONE** — no respawn after 30s+.
4. **0** AssetCache log lines in 5m.
5. Protected stack quiet: `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd`, `mobileassetd`, `audiomxd`, `audioaccessoryd`.
6. `softwareupdate --list` — OK.
7. `open -a "App Store"` — `appstoreagent` + `commerce`; no AssetCache respawn.

**Post full-off:** ~282 processes, ~4602 MB RSS.

**Verdict: keep full group disabled** on coding-only target.

## Expected Breakage

- Content Caching cannot be enabled/managed (Settings, `AssetCacheManagerUtil`)
- No LAN cache server discovery or local cache server
- No USB tethered iOS caching
- Direct CDN only; no LAN acceleration if a parent cache existed

## Expected Still Works

| Check | Result |
|-------|--------|
| SSH / network | OK |
| `softwareupdate --list` | OK |
| App Store (`appstoreagent`, `commerce`) | OK (headless) |
| Mac App Store install/update path | OK (same stack as prior App Store validations) |
| `mobileassetd`, protected stack | quiet |

## Notes

- **One feature group** — do not disable labels piecemeal in tweaker UI; expose as single question: *Content Caching?*
- `AssetCacheManagerService` alone is useless without workers; disable together.
- Do not confuse with `mobileassetd` (protected) — different Apple asset CDN layer.
- Card path uses `com.apple.AssetCache.builtin` as folder name (main server label); covers entire stack.