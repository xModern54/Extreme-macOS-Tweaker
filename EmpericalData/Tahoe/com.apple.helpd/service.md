# Help Indexer (helpd) — Disabled

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | macOS Help / app metadata indexer (`helpd`)                  |
| Category      | `spotlight` / `ui_required` (adjacent)                       |
| Risk Level    | 1 — Help search degraded; boot and dev workflow unaffected   |
| Status        | **Disabled** on target — headless PASS (2026-06-29)          |

## What It Does

`helpd` is a per-user LaunchAgent that indexes installed applications for the Help system:

- Watches `/Applications/` and `/Applications/Utilities/` via FSEvents (`WatchPaths`)
- Reads `InfoPlist.strings` / `.loctable` from every `.app` bundle
- Builds SQLite/cache under `~/Library/Caches/com.apple.helpd/` (~30 MB on target)
- Exposes Mach service `com.apple.helpd` and feeds **CoreSpotlightHelp Plugin** (Help search in Spotlight)
- Also listens for `com.apple.tips.content-updated` (Tips → help index refresh)

Functionally it is a **narrow, app-focused Spotlight sidecar for Help Viewer** — not general file indexing (that is `mds` / Spotlight, already disabled on this target).

## Observed Cost (before disable)

| Metric | Value |
|--------|-------|
| RSS | ~76 MB while resident |
| CPU | Burst at login (scanning 58 apps in `/Applications`), then ~0% idle |
| Disk cache | ~30 MB (`Cache.db`, `fsCachedData`, `Generated`) |
| Trigger | Login XPC event + app install changes under `/Applications` |

On target, `lsof` showed reads across system apps plus third-party installs (Xcode, ChatGPT, etc.) during the post-login scan.

## Launchd Labels

| Label | Domain | Plist | Binary |
|-------|--------|-------|--------|
| `com.apple.helpd` | gui | `/System/Library/LaunchAgents/com.apple.helpd.plist` | `/System/Library/PrivateFrameworks/HelpData.framework/Versions/A/Resources/helpd` |

**Related (not disabled):** `com.apple.tipsd` — Tips daemon; can notify helpd but does not respawn a disabled `helpd`.

**Related UI (demand):** `com.apple.helpviewer` — Help Viewer app; no always-on daemon.

## Disable

```bash
uid=$(id -u)
label=com.apple.helpd

launchctl bootout "gui/$uid/$label" 2>/dev/null || true
launchctl disable "gui/$uid/$label"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.helpd"
# reboot or wait for WatchPaths / client IPC to bootstrap it
sudo shutdown -r now
```

## Test Result

**2026-06-29 — helpd-off**

| Check | Result |
|-------|--------|
| Immediate process exit | PASS — `helpd` gone |
| `launchctl print-disabled` | PASS — `com.apple.helpd` => disabled |
| Reboot persistence | PASS — process did not return |
| SSH | PASS |
| Wi‑Fi / default route / DNS (en0) | PASS |
| Unified logs (`helpd`) | PASS — quiet since boot |
| `memory_pressure` | PASS — no regression at boot |

**Savings:** ~76 MB RSS removed; no post-login app-metadata scan under `/Applications`.

**GUI:** not yet confirmed — Help Viewer / Spotlight Help for apps expected broken or empty.

## Expected Breakage

- Help Viewer search and **Spotlight Help** results for applications will not work or will be stale
- System Settings → app help links may fail or show less context
- No impact on: file Spotlight (`mds` already off), SSH, networking, compilers, editors, package managers

## Notes

- Disabling `helpd` does **not** remove `~/Library/Caches/com.apple.helpd/`; cache can be deleted manually to reclaim ~30 MB disk (optional).
- `tipsd` remains enabled; harmless without `helpd`.
- Future tweaker question: *Do you use macOS Help / in-app help search?*