# Time Machine Core — Disabled

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | Time Machine core (`backupd-helper` + `backupd` + UI helper) |
| Category      | `disk_apfs`                                                  |
| Risk Level    | 2 — disables a macOS feature but should not break boot       |
| Status        | **Tier 1 disabled** on target — headless PASS (2026-06-29)   |

## What It Does

Time Machine backup infrastructure on macOS:

- **`backupd-helper`** — always-on launcher/orchestrator: schedules auto-backup XPC activities, listens for disk/power/keybag events, manages local APFS Time Machine snapshots, exposes `TMCacheDelete`
- **`backupd`** — main Time Machine engine (backup sessions, destination I/O); often resident even when idle
- **`TMHelperAgent`** — user-level UI for Time Machine notifications and cleanup prompts
- **`diagnosticextensions.osx.timemachine.helper`** — on-demand diagnostics extension for Feedback Assistant

On the target before disable: **no TM destination configured**, no local TM snapshots, but `backupd-helper` + `backupd` still consumed ~14 MB RSS.

**Not part of this group:** `com.apple.SecureBackupDaemon` (`sbd`) — secure/keychain item backup, separate CloudServices stack (Tier 2).

## Observed Cost (before disable)

| Process / service | Domain | RSS    | Always on? |
|-------------------|--------|--------|------------|
| `backupd-helper`  | system | ~7.7 MB | yes       |
| `backupd`         | system | ~6.6 MB | yes*      |
| `TMHelperAgent`   | gui    | 0      | event     |
| **Total**         |        | **~14 MB** |        |

\* `backupd` was running with `Running = 0` and no destinations; spawned via Mach IPC, not actively backing up.

## Launchd Labels

### System domain (3 labels)

| Label | Plist | Binary / program |
|-------|-------|------------------|
| `com.apple.backupd-helper` | `/System/Library/LaunchDaemons/com.apple.backupd-helper.plist` | `/System/Library/CoreServices/TimeMachine/backupd-helper -launchd` |
| `com.apple.backupd` | `/System/Library/LaunchDaemons/com.apple.backupd.plist` | `/System/Library/CoreServices/TimeMachine/backupd` |
| `com.apple.diagnosticextensions.osx.timemachine.helper` | `/System/Library/LaunchDaemons/com.apple.diagnosticextensions.osx.timemachine.helper.plist` | `osx-timemachine.appex` XPC helper |

### GUI domain (1 label)

| Label | Plist | Binary / program |
|-------|-------|------------------|
| `com.apple.TMHelperAgent` | `/System/Library/LaunchAgents/com.apple.TMHelperAgent.plist` | `TMHelperAgent.app` |

### Mach endpoints (not separate launchd jobs)

Registered by `backupd` / `backupd-helper`:

```text
com.apple.TMCacheDelete
com.apple.backupd-helper.status
com.apple.backupd
com.apple.backupd.xpc
com.apple.backupd.status.xpc
com.apple.backupd.session.xpc
com.apple.backupd.sandbox.xpc
com.apple.backupd-status
```

### XPC activities on `backupd-helper`

```text
com.apple.backupd-auto
com.apple.backupd-auto.dryspell
com.apple.backupd.analytics
```

## Disable

```bash
uid=$(id -u)

system_labels=(
  com.apple.backupd-helper
  com.apple.backupd
  com.apple.diagnosticextensions.osx.timemachine.helper
)
for label in "${system_labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done

gui_labels=(
  com.apple.TMHelperAgent
)
for label in "${gui_labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)

sudo launchctl enable system/com.apple.backupd-helper
sudo launchctl enable system/com.apple.backupd
sudo launchctl enable system/com.apple.diagnosticextensions.osx.timemachine.helper
launchctl enable "gui/$uid/com.apple.TMHelperAgent"

sudo shutdown -r now
```

## Test Result

**2026-06-29 — timemachine-off (Tier 1)**

| Check | Result |
|-------|--------|
| Immediate process exit | PASS — no `backupd`, `backupd-helper`, `TMHelperAgent` |
| `launchctl print-disabled` | PASS — all 4 labels disabled |
| Reboot persistence | PASS — processes did not return |
| SSH | PASS |
| Wi‑Fi / default route / DNS (en0) | PASS |
| `memory_pressure` | PASS — no regression observed at boot |
| Unified logs (`backupd` / `TimeMachine`) | PASS — quiet since boot |
| `tmutil status` | `Running = 0`; `No destinations configured` (unchanged) |
| `git` / `softwareupdate --list` | PASS |

**Savings:** ~14 MB RSS from removed always-on TM daemons; no periodic `backupd-auto` / analytics XPC from helper.

**GUI:** not yet confirmed by user — Time Machine pane in System Settings expected broken or empty.

## Expected Breakage

- Time Machine settings and backup UI non-functional
- `tmutil` backup/start operations fail or hang without `backupd`
- Local APFS Time Machine snapshots no longer created or thinned automatically
- TM user notifications (`TMHelperAgent`) will not appear
- Opening TM-related diagnostics in Feedback Assistant may fail (low impact)

Should **not** affect: boot, SSH, networking, keychain login, unrelated apps. `com.apple.SecureBackupDaemon` (`sbd`) remains running.

## Notes

- Target had no TM destination before test; benefit is mainly idle RAM + suppressed background scheduling, not backup traffic.
- Optional adjacent labels **not** disabled: `com.apple.diskspaced` (snapshot purge UI), `com.apple.SecureBackupDaemon`, `com.apple.AMP*` (iOS device backup), `com.apple.installandsetup.systemmigrationd`.
- Future tweaker feature question: *Do you use Time Machine backups on this Mac?*