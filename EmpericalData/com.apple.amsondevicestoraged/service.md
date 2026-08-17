# AMS on-device storage — `com.apple.amsondevicestoraged`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Process       | `amsondevicestoraged`                                                 |
| Binary        | `/System/Library/PrivateFrameworks/OnDeviceStorage.framework/Support/amsondevicestoraged` |
| Signing ID    | `com.apple.amsondevicestoraged`                                       |
| Plist         | `/System/Library/LaunchAgents/com.apple.amsondevicestoraged.plist`    |
| Domain        | `gui/<uid>`                                                           |
| Owner         | Apple (system)                                                        |
| Category      | `icloud` — AMS local cache / maintenance (not install pipeline)       |
| Risk Level    | **1** — on-device AMS storage janitor; not download/install core      |
| Profile       | **keep disabled** on coding-only target                               |

## What It Does

Maintains a **local encrypted SQLite store** for Apple Media Services (AMS) under:

`~/Library/Group Containers/group.com.apple.amsondevicestoraged/`

Concrete jobs (from binary task names):

| Task | Purpose |
|------|---------|
| `maintenance` / `online-maintenance` / `weekly-maintenance` | Scheduled DB cleanup (daily / weekly) |
| `CheckInstalledAppsTask` | Reconcile installed apps vs stored per-bundle records |
| `CheckInvalidAccessCredentialsTask` | Validate cached AMS access credentials |
| `FetchRevokedAccessCredentialsTask` | Pull revoked credentials and purge |
| `TTL cleanup` | Delete expired rows |
| `App data cleanup` | Purge bundle data on `applicationUnregistered` |

Exposes Mach service `com.apple.amsondevicestoraged.xpc`. `RunAtLoad: false` — on-demand / scheduled only.

**Not install/download:** `appstoreagent`, CommerceKit, `fairplayd`, `installcoordinationd` own the Store path. `amsaccountsd` remains the live AMS account layer.

## Observed Cost

| Metric | Value (target) |
|--------|----------------|
| RSS when running | ~16 MB (brief maintenance) |
| Idle | often not running |
| On-disk group container | ~4 KB (empty main-database on test machine) |
| CPU idle | 0% |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.amsondevicestoraged" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.amsondevicestoraged"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.amsondevicestoraged"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.amsondevicestoraged.plist
sudo shutdown -r now
```

## Test Result (2026-06-28, target `codexadmin` uid 502)

**Scope:** single label only. Protected App Store / auth / audio stack not touched.

### Pre-disable baseline

- `amsondevicestoraged` running (pid 652) during session maintenance window.
- Group container 4 KB; `main-database` empty (0 bytes).
- ~301 processes, ~5399 MB total RSS.

### Disable + clean reboot

1. `launchctl disable gui/502/com.apple.amsondevicestoraged` + reboot.
2. SSH, Wi‑Fi/route OK.
3. `amsondevicestoraged` **NOT RUNNING**; disable flag intact; service absent from `launchctl print`.
4. 30s + 60s delayed checks — **no respawn**.
5. **0** log lines for `amsondevicestoraged` / `OnDeviceStorage` in 5m; **0** `amsaccountsd`/`appstoreagent` error/retry lines.
6. Group container unchanged (4 KB, empty DB) — no retry/cache spam growth.
7. Protected stack quiet (0% CPU): `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd`, `audiomxd`, `audioaccessoryd`, `akd`, `accountsd`, `secd`, `trustd`, `tccd`.
8. `softwareupdate --list` — OK.
9. `open -a "App Store"` — App Store + `appstoreagent` + `amsaccountsd` + `commerce` spawned cleanly.

**Post-reboot:** ~285 processes, ~4705 MB RSS (boot variance; `amsondevicestoraged` absent).

**Verdict: keep disabled** on coding-only target.

### GUI test (pending user confirmation)

Headless App Store launch OK. User should confirm free app install/update from App Store UI (same as `appplaceholdersyncd` validation).

## Expected Breakage

- No local AMS on-device storage maintenance.
- No cleanup of cached AMS credentials / TTL / ownership index on this Mac.
- Possible slower first Store/AMS lookup; AMS cache may rebuild via `amsaccountsd`/network instead.
- Group container may stay empty or unused.

## Expected Still Works (verified headless)

| Check | Result |
|-------|--------|
| SSH / network | OK |
| `softwareupdate --list` | OK |
| App Store app launch | OK |
| `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd` | running, quiet |
| `akd`, `accountsd`, `secd`, `trustd`, `tccd` | running |
| Audio stack | `audiomxd` / `audioaccessoryd` 0% CPU |
| No amsondevicestoraged log storm | OK |

## Notes

- Do not batch with `amsaccountsd`, `appstoreagent`, CommerceKit, or Apple ID stack.
- AMS = Apple Media Services; this daemon is **local cache janitor**, not the account or install daemon.
- Future tweaker: *“Keep AMS on-device credential cache on this Mac?”* → default **no** on coding profile.