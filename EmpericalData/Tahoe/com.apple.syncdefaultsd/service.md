# iCloud KVS / synced defaults — `com.apple.syncdefaultsd`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | iCloud Key-Value Store (KVS) / SyncedDefaults only                    |
| Process       | `syncdefaultsd`                                                       |
| Binary        | `/System/Library/PrivateFrameworks/SyncedDefaults.framework/Support/syncdefaultsd` |
| Plist         | `/System/Library/LaunchAgents/com.apple.syncdefaultsd.plist`          |
| Domain        | `gui/<uid>`                                                           |
| Category      | `icloud` — synced prefs / NSUbiquitousKeyValueStore                   |
| Risk Level    | **2** — breaks cross-device prefs sync; not boot/install critical     |
| Profile       | **keep disabled** on coding-only target without iCloud KVS needs      |

## What It Does

Daemon for **SyncedDefaults** / iCloud **KVS** (`com.apple.kvsd`, `com.apple.aps.kvsd`):

- Syncs small key-value defaults across devices (not iCloud Drive files).
- CloudKit SyncEngine background tasks; related surfaces: Apple ID Settings, Mail, WiFi agents.
- Sandbox reads/writes `com.apple.CloudKit` prefs domain.

**Not:** iCloud Drive (`bird`), CloudKit document sync (`cloudd`), local Keychain, App Store install path, `iCloudHelper` (Apple ID account ops).

## Observed Cost

| Metric | Before disable |
|--------|----------------|
| RSS warm | ~27 MB |
| CPU idle | 0% |
| RunAtLoad | no — on-demand via Mach, stays warm after first lookup |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.syncdefaultsd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.syncdefaultsd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.syncdefaultsd"
# respawn on KVS Mach lookup, or:
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.syncdefaultsd.plist
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Scope:** single label `com.apple.syncdefaultsd` only. `iCloudHelper`, `bird`, `cloudd`, CloudTelemetry, auth/App Store/audio stacks not touched.

### Pre-disable

- `syncdefaultsd` running ~27 MB; ~268 processes; ~4346 MB RSS sum.

### Disable + clean reboot

1. `bootout` + `disable` — process gone; flag set.
2. Reboot — SSH ~18s; Wi‑Fi/DNS/route OK.
3. Post-reboot: **NOT RUNNING**; disable flag intact; service absent from `launchctl print`.
4. 60s delayed check — **no respawn**.
5. **0** `syncdefaultsd`/`kvsd` error/retry lines in 5m log window; **0** `accountsd`/`akd` error burst.
6. `softwareupdate --list` — OK (CLT + macOS updates listed).
7. `open -a "App Store"` — App Store + `appstoreagent` + `commerce` + `storeuid`; **no** `syncdefaultsd` respawn.
8. Protected stack quiet (0% CPU idle): `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd`, `mobileassetd`, `akd`, `accountsd`, `secd`, `trustd`, `audiomxd`, `audioaccessoryd`, `coreaudiod`.
9. `bird` + `cloudd` still running (iCloud Drive/CloudKit untouched).
10. Keychain headless: login keychain listable/accessible.

**Post-reboot delta:** ~27 MB saved (syncdefaultsd absent); process count similar.

**Verdict: keep disabled** on coding target.

### GUI-confirmed (user, 2026-06-29)

On target with full current disable stack:

- **Desktop/Finder/Dock** — normal
- **Apple Account settings** — no hard crash
- **Cross-device prefs sync** — disabled/broken as expected (KVS off)

App Store install/update not re-tested this round; prior cumulative stack validations still apply.

## Expected Breakage

- iCloud synced app preferences (`NSUbiquitousKeyValueStore`).
- Cross-device settings sync via KVS.
- Possible Mail / Wi‑Fi / Apple ID **synced settings drift** (local values remain).

**Not broken (headless verified):** SSH/network, local keychain access, `softwareupdate --list`, App Store spawn, auth daemons quiet, iCloud Drive/CloudKit daemons still up, audio stack idle.

## Notes

- Do not batch with `bird`, `cloudd`, `iCloudHelper`, `akd`, or `accountsd`.
- Future tweaker question: *"Sync small iCloud preferences across devices (KVS)?"* → default **no** on coding profile.
- Full iCloud-off is a separate `bird`+`cloudd` group, not this label.