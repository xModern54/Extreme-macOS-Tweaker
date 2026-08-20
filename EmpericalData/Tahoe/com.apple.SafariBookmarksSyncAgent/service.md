# Per-app / legacy sync tails off — `per-app-sync-tails-off`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **per-app-sync-tails-off** — Safari/Maps/Exchange/legacy sync agents  |
| Profile       | no-iCloud / no-sync coding target                                     |
| Risk Level    | **1** — per-app sync tails; not boot/auth critical                    |
| Verdict       | **keep disabled** on experimental coding target — headless PASS       |

## What It Does (disabled stack)

| Label | Role |
|-------|------|
| `com.apple.SafariBookmarksSyncAgent` | Safari **iCloud bookmarks** sync |
| `com.apple.Safari.History` | Safari **iCloud history** sync |
| `com.apple.Maps.mapssyncd` | **Maps** cloud sync |
| `com.apple.UserPictureSyncAgent` | Apple ID **avatar** sync |
| `com.apple.cmfsyncagent` | **CoreMedia** sync |
| `com.apple.exchange.exchangesyncd` | **Exchange** calendar/mail sync daemon |
| `com.apple.StatusKitAgent` | **Status/presence** kit sync |
| `com.apple.syncservices.SyncServer` | Legacy **Sync Services** server |
| `com.apple.syncservices.uihandler` | Legacy Sync Services UI |
| `com.apple.AOSHeartbeat` | Legacy **AOS** heartbeat |
| `com.apple.dataaccess.dataaccessd` | **DataAccess** (CalDAV/CardDAV/Exchange accounts) |

All gui `LaunchAgents`, on-demand. Pre-disable warm: `SafariBookmarksSyncAgent`, `Safari.History`.

## Checked, already disabled (not touched)

| Label | Status |
|-------|--------|
| `com.apple.replicatord` | already disabled |
| `com.apple.AOSPushRelay` | already disabled |

## Prerequisite

- App Store Stage A+B+C off
- iCloud Drive Stage 1 off — `services/com.apple.bird/service.md`
- iCloud sync tails off — `services/com.apple.cloudsettingssyncagent/service.md`

## Explicitly NOT disabled

`cloudd` gui/system, `iCloudHelper`, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, keychain cloud proxy labels, `softwareupdated*`, `mobileassetd`, audio, network.

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.SafariBookmarksSyncAgent
  com.apple.Safari.History
  com.apple.Maps.mapssyncd
  com.apple.UserPictureSyncAgent
  com.apple.cmfsyncagent
  com.apple.exchange.exchangesyncd
  com.apple.StatusKitAgent
  com.apple.syncservices.SyncServer
  com.apple.syncservices.uihandler
  com.apple.AOSHeartbeat
  com.apple.dataaccess.dataaccessd
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback (per-app tails only)

```bash
uid=$(id -u)
labels=(
  com.apple.SafariBookmarksSyncAgent
  com.apple.Safari.History
  com.apple.Maps.mapssyncd
  com.apple.UserPictureSyncAgent
  com.apple.cmfsyncagent
  com.apple.exchange.exchangesyncd
  com.apple.StatusKitAgent
  com.apple.syncservices.SyncServer
  com.apple.syncservices.uihandler
  com.apple.AOSHeartbeat
  com.apple.dataaccess.dataaccessd
)
for label in "${labels[@]}"; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `per-app-sync-tails-off` — 11 labels disabled; `replicatord` + `AOSPushRelay` skipped (already off); clean reboot.

### Inventory

| Action | Labels |
|--------|--------|
| **Touched (11)** | all listed above — existed, were enabled |
| **Skipped (2)** | `replicatord`, `AOSPushRelay` — already disabled |

### Headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| 11 touched labels disabled, not running | **PASS** |
| Stage 1 + sync tails still disabled | **PASS** |
| 60s no respawn | **PASS** |
| `cloudd` running | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` | **PASS** |
| `softwareupdate --list` | **PASS** |
| Keychain | **PASS** |
| Local Desktop/Documents/Downloads | **PASS** |
| Safari + Terminal + Happ + Finder + Settings | **PASS** |
| Audio idle | **PASS** |
| Rollback | **not needed** |

### Logs

| Signal | Result |
|--------|--------|
| Per-app tail errors | **1** |
| Per-app failed lookup | **10** — Safari/accountsd burst at login; no loop |
| `cloudd` / auth errors | boot-level noise; **no storm**; `apsd` still off |

### GUI

Pending user (expected: Safari browses locally, Settings shell OK).

## Expected Breakage

- Safari iCloud bookmarks/history sync
- Maps sync, avatar sync, Exchange/DataAccess sync
- Legacy SyncServices, StatusKit, AOS heartbeat

## Expected Still Works

- Safari local browsing; local bookmarks/history on disk
- Finder, local files, Settings, Apple Account shell
- Local keychain, `softwareupdate`, network, audio, installed apps

## Notes

- `accountsd` may log failed lookup to `dataaccessd` — expected, not fatal.
- `Maps.mapspushd` was already disabled from earlier work (not in this batch).
- Next slices: `liveactivitiesd`, family controls, or staged `cloudd` trim — separate cards.

## Related

- `services/com.apple.bird/service.md`
- `services/com.apple.cloudsettingssyncagent/service.md`
- `services/com.apple.syncdefaultsd/service.md`