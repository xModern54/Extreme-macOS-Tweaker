# Media stores — `itunescloudd` + `bookdatastored` (media-stores-off)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Apple Music/iTunes Cloud + Apple Books data store only         |
| Category      | `consumer_apps_media` — not Mac App Store install path         |
| Risk Level    | **1** — separate media-store tails                             |
| Profile       | **keep disabled** on coding-only target                        |

## What It Does

Two independent on-demand LaunchAgents (not Mac App Store):

### `com.apple.itunescloudd`

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/PrivateFrameworks/iTunesCloud.framework/Support/itunescloudd` |
| Plist   | `/System/Library/LaunchAgents/com.apple.itunescloudd.plist` |
| Domain  | `gui/<uid>` |

Apple Music / iTunes Cloud session daemon: MusicKit tokens, subscription status, library auth, play activity, music push, remote requests, offline keys for **music** downloads.

Mach: `itunescloudd.xpc`, `library-auth-token-provider`, `music-subscription-status-service`, `aps.itunescloudd`, etc. `RunAtLoad: false`.

### `com.apple.bookdatastored`

| Field   | Value |
|---------|-------|
| Binary  | `/System/Library/PrivateFrameworks/BookDataStore.framework/Support/bookdatastored` |
| Plist   | `/System/Library/LaunchAgents/com.apple.bookdatastored.plist` |
| Domain  | `gui/<uid>` |

Apple Books local/cloud data store: library, collections, reading position/history, CloudKit sync. Wakes on `com.apple.kvs.store-did-change.com.apple.iBooks`. `RunAtLoad: false`.

Mach: `com.apple.iBooks.BookDataStoreService`, `com.apple.aps.bookdatastored`.

**Not touched / unrelated:** `appstoreagent`, `commerce`, `storeuid`, `amsaccountsd`, `fairplayd`, `installcoordinationd`, `softwareupdated*`.

## Observed Cost

| Process | Idle on target | When running (kickstart research) |
|---------|----------------|-----------------------------------|
| `itunescloudd` | not running | ~33–49 MB |
| `bookdatastored` | not running | ~22 MB |

Both were **0 MB at boot** before disable (on-demand only).

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.itunescloudd
  com.apple.bookdatastored
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.itunescloudd com.apple.bookdatastored; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
# bootstrap on demand when Music/Books opened, or:
# launchctl bootstrap gui/$uid /System/Library/LaunchAgents/com.apple.<label>.plist
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Scope:** media-stores group only. App Store / auth / audio protected stack not touched.

### Pre-disable baseline

- Both not running at capture time.
- ~314 processes, ~5809 MB total RSS.

### Disable + clean reboot

1. Disabled both labels + reboot.
2. SSH, Wi‑Fi/route OK.
3. `itunescloudd` and `bookdatastored` **NOT RUNNING**; both disable flags intact; services absent from `launchctl print`.
4. 30s + 60s delayed — **no respawn**.
5. **0** log lines for either daemon in 5m; **0** `appstoreagent`/`amsaccountsd` error/retry lines.
6. Protected stack quiet (0% CPU idle after settle): `appstoreagent`, `amsaccountsd`, `fairplayd`, `commerce`, `storeuid`, `installcoordinationd`, `audiomxd`, `audioaccessoryd`, `akd`, `accountsd`.
7. `softwareupdate --list` — OK (CLT + macOS updates).
8. `open -a "App Store"` — `appstoreagent`, `commerce`, `storeuid` spawned; no store error logs.

**Post-reboot:** ~300 processes, ~5099 MB RSS (boot variance; both media daemons absent at idle).

**Verdict: keep disabled** on coding-only target.

### GUI-confirmed (user, 2026-06-29)

On target with full current disable stack: **App Store works** — user verified free app install/update after `media-stores-off` + reboot.

## Expected Breakage

### `itunescloudd`

- Apple Music cloud / Music.app cloud features
- MusicKit developer/user tokens, subscription status
- iTunes Cloud library sync, play activity
- Music push / remote requests
- Offline keys for **music** downloads

### `bookdatastored`

- Books.app library and cloud sync
- Reading position/history sync
- iBooks KVS-driven store updates
- `BookDataStoreService` for Books

## Expected Still Works (verified)

| Check | Result |
|-------|--------|
| SSH / network | OK |
| `softwareupdate --list` | OK |
| App Store spawn (`appstoreagent`, `commerce`, `storeuid`) | OK |
| **App Store free app install/update** | **OK (GUI-confirmed)** |
| `amsaccountsd`, `fairplayd`, `installcoordinationd` | running, quiet |
| Audio stack | `audiomxd` / `audioaccessoryd` 0% CPU |
| No media-store log storm | OK |

**Not broken (by design):** Mac App Store app install/update backend, `softwareupdate`, already-installed apps.

## Notes

- Research showed `open App Store` does **not** start either daemon; they are Music/Books tails.
- Safe to disable as a **pair** or individually; no shared KeepAlive.
- Do not batch with `appstoreagent`, CommerceKit, or Apple ID stack.
- Future tweaker: *“Use Apple Music or Books on this Mac?”* → default **no** on coding profile.