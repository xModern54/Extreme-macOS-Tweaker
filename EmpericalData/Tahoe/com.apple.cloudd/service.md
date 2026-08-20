# CloudKit hub off — `cloudd-off`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **cloudd-off** — CloudKit daemon hub (gui + system)                   |
| Profile       | no-iCloud / no-sync coding target — hub kill after client trims       |
| Risk Level    | **3** — CloudKit dead; Settings iCloud shell may degrade              |
| Verdict       | **keep disabled** on experimental coding target — headless + GUI PASS   |

## What It Does (disabled)

| Label | Domain | Binary | Role |
|-------|--------|--------|------|
| `com.apple.cloudd` | gui | `CloudKitDaemon.framework/.../cloudd` | Per-user **CloudKit** hub — app DBs, account CloudKit, telemetry activities |
| `com.apple.cloudd` | system | same + `--system` | System CloudKit / cloud assets |

Spawn: on-demand via Mach (`ipc`); warm ~45 MB total (gui ~30 MB + system ~15 MB) when enabled.

**Not** iCloud Drive (`bird`/`FileProvider` — already off in Stage 1).

## Prerequisite (all validated, stay disabled)

- App Store Stage A+B+C
- iCloud Drive Stage 1: `bird`, `FileProvider`, `cloudphotod`
- Sync tails: `cloudsettingssyncagent`, `icloudmailagent`, `icloudwebd`, `ckdiscretionaryd`, `coredatad`
- Per-app tails: see `services/com.apple.SafariBookmarksSyncAgent/service.md`
- `replicatord`, `AOSPushRelay` already off

## Explicitly NOT disabled

`akd`, `accountsd`, `secd`, `securityd`, `trustd`, `iCloudHelper`, `protectedcloudstorage.protectedcloudkeysyncing`, `security.cloudkeychainproxy3`, `systemkeychain`, `softwareupdated*`, `mobileassetd`, Finder/Dock/audio/network.

## Observed Cost (before disable)

| Metric | Value |
|--------|-------|
| `cloudd` RSS | ~45 MB (gui+system) |
| `CloudTelemetryService.xpc` | 4 instances pre → **1–2** post (cloudd-hosted instances gone) |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.cloudd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.cloudd"
sudo launchctl bootout system/com.apple.cloudd 2>/dev/null || true
sudo launchctl disable system/com.apple.cloudd
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.cloudd"
sudo launchctl enable system/com.apple.cloudd
sudo shutdown -r now
```

Does not re-enable Stage 1 / sync tails / per-app batches.

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `cloudd-off` — disable gui+system; clean reboot.

### Headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| `cloudd` gui disabled, not running | **PASS** |
| `cloudd` system disabled, not running | **PASS** |
| Prior iCloud/sync labels still disabled | **PASS** |
| 60s no respawn | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` / `securityd` functional | **PASS** |
| `softwareupdate --list` | **PASS** |
| Keychain | **PASS** |
| Local Desktop/Documents/Downloads | **PASS** |
| Safari + Terminal + Happ + Finder + Settings launch | **PASS** |
| Audio idle | **PASS** |
| Rollback | **not needed** |

### CloudTelemetry delta

| When | CloudTelemetryService instances |
|------|--------------------------------|
| Pre-disable | **4** |
| Post-disable (immediate) | **2** |
| Post-reboot | **1–2** |

cloudd-hosted telemetry XPC reduced; some instances remain from other hosts.

### Logs

| Signal | Result |
|--------|--------|
| `cloudd` process log lines since boot | **1** (minimal) |
| `failed lookup: com.apple.cloudd` | **~31** — burst from `transparencyd`, `secd`, Settings clients at login; **no respawn loop** |
| CloudKit errors | **~21** — expected client failures |
| `akd` / accountsd / trustd storm | **no** — functional; boot-level error counts normal |

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| Settings opens | **PASS** |
| iCloud tabs / subpages | **FAIL (expected)** — «вкладки iCloud наебнулись и больше не открываются» |
| Desktop / local apps | **PASS** — prior behavior unchanged |
| Hard crash (Settings overall) | **PASS** — no system-wide crash reported |

**Interpretation:** `cloudd-off` kills CloudKit backend for Settings iCloud UI. Acceptable on no-iCloud coding target; rollback `cloudd` gui+system if iCloud Settings access needed again.

## Expected Breakage

- CloudKit API dead
- iCloud app databases / Notes cloud / container sync dead
- CloudTelemetry tasks tied to cloudd gone
- Apple Account/iCloud Settings data loading degraded

## Expected Still Works

- Desktop GUI, local files, Finder local browse
- Local keychain, `softwareupdate`, network, audio
- Installed apps, Safari local browsing
- `akd`/`accountsd` base Apple ID (without CloudKit backend)

## Notes

- **Why it was warm before:** Settings/iCloud tab, `accountsd`, `transparencyd`, `secd` poke CloudKit Mach services — not because file sync was alive.
- **`apsd` off** removes push path; cloudd was already half-idle complaining about push.
- Next nuclear slices (separate): `cloudkeychainproxy3`, `protectedcloudkeysyncing` — risk 3–4.

## Related

- `services/com.apple.bird/service.md`
- `services/com.apple.cloudsettingssyncagent/service.md`
- `services/com.apple.SafariBookmarksSyncAgent/service.md`