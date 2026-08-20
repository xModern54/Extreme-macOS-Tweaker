# iCloud Drive off — Stage 1 (`icloud-drive-stage-1-off`)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **icloud-drive-stage-1-off** — iCloud Drive + FileProvider host + Photos cloud tail |
| Profile       | no-iCloud / no-sync coding target (Drive slice only)                   |
| Risk Level    | **2–3** — breaks Drive/FP; not boot/auth critical                    |
| Verdict       | **keep disabled** on experimental coding target — headless + GUI PASS |

## What It Does (disabled stack)

### `com.apple.bird` (gui)

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/PrivateFrameworks/iCloudDriveCore.framework/Versions/A/Support/bird` |
| Plist   | `/System/Library/LaunchAgents/com.apple.bird.plist` |
| Role    | **CloudDocs / iCloud Drive core** — ubiquity containers, `brctl`, session DB under `~/Library/Application Support/CloudDocs/` |
| Spawn   | on-demand via Mach (`immediate reason = ipc`); stays warm when enabled |
| Mach    | `com.apple.bird`, `.push`, `.token`, `.cache-delete` |
| Events  | `dasd` maintenance, app install/uninstall `distnoted` |

### `com.apple.FileProvider` (gui)

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/PrivateFrameworks/FileProvider.framework/Support/fileproviderd` |
| Plist   | `/System/Library/LaunchAgents/com.apple.FileProvider.plist` |
| Role    | **FileProvider host** for all non-UI providers; fsevents on `~/Library/CloudStorage` |
| Spawn   | on-demand via Mach; launches extensions including `CloudDocs.iCloudDriveFileProvider` |
| Note    | Also hosts `com.apple.Photos.PhotosFileProvider` — disable affects Photos FP |

### `com.apple.cloudphotod` (gui)

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/PrivateFrameworks/CloudPhotoLibrary.framework/.../cloudphotod` |
| Plist   | `/System/Library/LaunchAgents/com.apple.cloudphotod.plist` |
| Role    | **iCloud Photos library** sync/maintenance (not Drive); was idle pre-disable |
| Events  | `dasd` tasks; InvolvedProcesses include `cloudd`, `photolibraryd`, `nsurlsessiond` |

### No separate launchd label (die with Stage 1)

- `com.apple.CloudDocs.iCloudDriveFileProvider` (appex, child of `fileproviderd`)
- `ContainerMetadataExtractor.xpc` (on-demand child)

## Explicitly NOT disabled

`cloudd` gui/system, `iCloudHelper` XPC, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, `softwareupdated*`, `mobileassetd`, audio, network.

**Prerequisite:** App Store Stage A+B+C off; `apsd` already disabled on target.

## Observed Cost (before disable)

| Process | RSS warm |
|---------|----------|
| `bird` | ~24 MB |
| `fileproviderd` | ~33 MB |
| `CloudDocs.iCloudDriveFileProvider` | ~14 MB |
| `ContainerMetadataExtractor` | ~12 MB |
| **Stack total** | **~83 MB** |

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.bird
  com.apple.FileProvider
  com.apple.cloudphotod
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback (Stage 1 only)

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.bird"
launchctl enable "gui/$uid/com.apple.FileProvider"
launchctl enable "gui/$uid/com.apple.cloudphotod"
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `icloud-drive-stage-1-off` — disable bird + FileProvider + cloudphotod; clean reboot.

### Disable + reboot — headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| `bird` disabled, not running | **PASS** |
| `fileproviderd` / FileProvider disabled, not running | **PASS** |
| `CloudDocs.iCloudDriveFileProvider` absent | **PASS** |
| `cloudphotod` disabled, not running | **PASS** |
| 60s no respawn | **PASS** |
| `cloudd` gui+system still running | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` running, functional | **PASS** |
| `softwareupdate --list` | **PASS** |
| `security list-keychains` | **PASS** |
| `~/Desktop` / `~/Documents` / `~/Downloads` local files listed | **PASS** |
| Safari + Terminal + Happ launch | **PASS** |
| Finder opens (headless `open -a Finder`) | **PASS** |
| Settings opens | **PASS** |
| Audio idle (`coreaudiod`, `audiomxd` ~0% CPU) | **PASS** |
| Rollback | **not needed** |

**Savings:** ~83 MB warm Drive/FP stack absent.

### Logs

| Signal | Result |
|--------|--------|
| `failed lookup` bird/FileProvider | **expected** — burst at login/Finder (~46 since boot); not infinite respawn loop |
| `brctl status` | fails with bird XPC 4099 — **expected** |
| `cloudd` push token errors (1015) | present — **apsd already disabled**; not Stage 1 regression |
| auth/trustd error storm | **no** — elevated trustd chatter at boot, no crash loop; akd quiet functionally |

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| Basic installed apps launch | **PASS** — «приложения нормально запускаются» |
| Settings → iCloud tab | **PASS** — tab loads, toggles/services UI visible (account shell intact via `akd`/`accountsd`/`cloudd`) |
| iCloud sync / Drive upload-download | **FAIL (expected)** — sync dead; user OK («нахуй и не нужна была») |
| Desktop / coding workflow | **PASS** — «всё нормально» |
| App Store | **dead expected** (Stage A+B+C; not retested) |

**Interpretation:** Stage 1 kills **Drive/FileProvider sync path** (`bird`/`fileproviderd`), not Apple Account / Settings iCloud **UI shell**. Settings can still enumerate iCloud services while actual file/container sync is offline.

## Expected Breakage (confirmed headless)

- iCloud Drive / CloudDocs / `brctl`
- Finder iCloud Drive provider
- `~/Library/Mobile Documents` / `CloudStorage` cloud FP path
- Desktop & Documents **iCloud** sync coordination
- Per-app iCloud document container sync
- Photos FileProvider host + future `cloudphotod` sync

## Expected Still Works (confirmed headless)

- Local Desktop/Documents/Downloads files on disk
- Finder local browse
- Installed apps (Safari, Terminal, Happ)
- Local keychain listable
- `softwareupdate` CLI
- Network, audio, DMG/PackageKit install path
- Apple ID base daemons (`akd`, `accountsd`, `secd`)
- `cloudd` (other CloudKit clients may still run)

## Notes

- **`FileProvider` is shared infrastructure** — not Drive-only; Photos FP affected.
- **`cloudd` must stay** for later staged iCloud trims; Drive disable does not remove CloudKit hub.
- Next iCloud slices: settings/mail/web tails, `replicatord`, Safari/Maps sync, keychain cloud proxy — separate cards.
- Research: `icloud-drive-stage-1-research` (pre-disable).

## Related

- App Store nuclear stack: `services/com.apple.installcoordinationd/service.md`
- KVS sync (already off): `services/com.apple.syncdefaultsd/service.md`