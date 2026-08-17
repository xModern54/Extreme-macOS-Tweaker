# iCloud sync tails off — `icloud-sync-tails-off`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **icloud-sync-tails-off** — obvious CloudKit/iCloud helper tails      |
| Profile       | no-iCloud / no-sync coding target (tails slice)                        |
| Risk Level    | **1–2** — on-demand helpers; not boot/auth critical                  |
| Verdict       | **keep disabled** on experimental coding target — headless + GUI PASS |

## What It Does (disabled stack)

| Label | Binary / role |
|-------|----------------|
| `com.apple.cloudsettingssyncagent` | iCloud **Settings sync** across devices |
| `com.apple.icloudmailagent` | **iCloud Mail** background agent |
| `com.apple.icloudwebd` | **iCloud web** service helpers |
| `com.apple.ckdiscretionaryd` | **Discretionary CloudKit** background tasks |
| `com.apple.coredatad` | **CloudKit Core Data** sync daemon |

All gui/`LaunchAgents`, on-demand (only `icloudwebd` was warm ~28 MB pre-disable on target).

## Prerequisite

- App Store Stage A+B+C off
- iCloud Drive Stage 1 off: `bird`, `FileProvider`, `cloudphotod` — see `services/com.apple.bird/service.md`

## Explicitly NOT disabled

`cloudd` gui/system, `iCloudHelper`, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, `protectedcloudstorage.protectedcloudkeysyncing`, `security.cloudkeychainproxy3`, `softwareupdated*`, `mobileassetd`, audio, network.

## Observed Cost

| Metric | Before disable |
|--------|----------------|
| `icloudwebd` warm | ~28 MB (only warm tail) |
| Other four | idle at snapshot |

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.cloudsettingssyncagent
  com.apple.icloudmailagent
  com.apple.icloudwebd
  com.apple.ckdiscretionaryd
  com.apple.coredatad
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback (tails group only)

```bash
uid=$(id -u)
labels=(
  com.apple.cloudsettingssyncagent
  com.apple.icloudmailagent
  com.apple.icloudwebd
  com.apple.ckdiscretionaryd
  com.apple.coredatad
)
for label in "${labels[@]}"; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

Stage 1 rollback separate in `services/com.apple.bird/service.md`.

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `icloud-sync-tails-off` — disable 5 gui labels; clean reboot.

### Headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| All 5 tail labels disabled, not running | **PASS** |
| Stage 1 (`bird`/`FileProvider`/`cloudphotod`) still disabled, not running | **PASS** |
| 60s no respawn | **PASS** |
| `cloudd` gui+system running | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` running | **PASS** |
| `softwareupdate --list` | **PASS** |
| `security list-keychains` | **PASS** |
| Local Desktop/Documents/Downloads | **PASS** |
| Safari + Terminal + Happ + Finder + Settings launch | **PASS** |
| Audio idle | **PASS** |
| Rollback | **not needed** |

### Logs

| Signal | Result |
|--------|--------|
| Tail process errors since boot | **1** |
| Tail `failed lookup` | **5** — expected, no loop |
| `cloudd` errors | **~265** — mostly push/persona noise; **apsd off** + boot churn; not tail-specific storm |
| `akd` / accountsd / trustd storm | **no** — functional daemons OK |

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| Basic apps launch | **PASS** — same as after Stage 1 |
| Settings → iCloud tab | **PASS** — loads, UI visible |
| Sync / cloud-backed data | **dead expected** — user OK |
| Desktop / coding workflow | **PASS** — «поведение такое же» |

**Interpretation:** Sync tails off does not regress Stage 1 UX. Settings shell still works via `akd`/`accountsd`/`cloudd`; additional tail daemons were mostly idle anyway.

## Expected Breakage

- iCloud settings cross-device sync
- iCloud Mail agent
- iCloud web helpers
- Discretionary CloudKit tasks
- CloudKit Core Data app sync

## Expected Still Works

- Desktop GUI, local files, Finder local browse
- Settings / Apple Account shell (`akd`/`accountsd`/`cloudd`)
- Local keychain, `softwareupdate`, network, audio
- Installed apps, DMG install path
- Stage 1 Drive remains off

## Notes

- **`cloudd` stays warm** — Settings iCloud tab can still load; file/KVS/settings-tail sync paths further reduced.
- Next slices: per-app sync (`SafariBookmarksSyncAgent`, `Maps.mapssyncd`, …), `replicatord`, keychain cloud proxy — separate groups.

## Related

- iCloud Drive Stage 1: `services/com.apple.bird/service.md`
- KVS (already off): `services/com.apple.syncdefaultsd/service.md`