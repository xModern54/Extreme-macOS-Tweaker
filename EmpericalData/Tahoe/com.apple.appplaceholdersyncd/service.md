# App placeholder cross-device sync — `com.apple.appplaceholdersyncd`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Process       | `appplaceholdersyncd`                                                 |
| Binary        | `/System/Library/CoreServices/appplaceholdersyncd`                  |
| Signing ID    | `com.apple.appplaceholdersyncd`                                       |
| Plist         | `/System/Library/LaunchAgents/com.apple.appplaceholdersyncd.plist`    |
| Domain        | `gui/<uid>`                                                           |
| Owner         | Apple (system)                                                        |
| Category      | `icloud` — cross-device app placeholder sync                          |
| Risk Level    | **1** — cosmetic/ecosystem continuity; not install pipeline           |
| Profile       | **keep disabled** on coding-only target                               |

## What It Does

Syncs **placeholder app icons** between paired Apple devices via replicator notifications:

- When an app is installed on iPhone/iPad but not on Mac, Dock/Launchpad can show a **ghost/placeholder** icon (`isPlaceholder`).
- Listens to `com.apple.replicatord.devicesChanged`, `records-received`, `messages-received`, `enabled-devices-changed`, local `application-installed` / `application-uninstalled`.
- Exposes Mach service `com.apple.appplaceholdersync`.
- If no paired devices: purges icon services cache (per binary strings).

**Not part of App Store download/install:** catalog, download, DRM, and install coordination live in `appstoreagent`, CommerceKit (`commerce`, `storedownloadd`, …), `fairplayd`, `installcoordinationd`.

## Observed Cost

| Metric   | Before disable (target idle) |
|----------|------------------------------|
| RSS      | ~12–13 MB                    |
| CPU idle | 0%                           |
| RunAtLoad| true (always started at login)|

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.appplaceholdersyncd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.appplaceholdersyncd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.appplaceholdersyncd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.appplaceholdersyncd.plist
sudo shutdown -r now
```

## Test Result (2026-06-28, target `codexadmin` uid 502)

**Scope:** single label only. Protected stack explicitly not touched.

### Pre-disable baseline

- `appplaceholdersyncd` running ~13 MB, 0% CPU.
- ~293 processes, ~5073 MB total RSS.

### Disable + clean reboot

1. `launchctl disable gui/502/com.apple.appplaceholdersyncd` + reboot.
2. SSH returned; Wi‑Fi/DNS/route OK.
3. `appplaceholdersyncd` **NOT RUNNING**; disable flag intact; service absent from `launchctl print`.
4. 30s + 60s delayed checks — **no respawn**, **0** log lines matching `appplaceholdersync` in 5m window.
5. Protected stack quiet (0% CPU idle): `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd`, `audiomxd`, `audioaccessoryd`.
6. `softwareupdate --list` — OK (CLT + macOS updates listed).
7. `open -a "App Store"` — App Store process + `appstoreagent` + `commerce` spawned; no `appstoreagent` errors in 2m log window.
8. No error/retry storm from `replicatord` / `iconservicesagent` in log sample.

**Post-reboot:** ~295 processes (App Store open during check); `appplaceholdersyncd` absent (~13 MB saved when idle).

**Verdict: keep disabled** on coding-only target.

### GUI-confirmed (user, 2026-06-28)

On target with full current disable stack: **App Store app install works** — user verified end-to-end free app download/install after `appplaceholdersyncd-off` + reboot.

## Expected Breakage

- No sync of ghost/placeholder app icons from iPhone/iPad to Mac Dock/Launchpad.
- Cross-device placeholder state via `com.apple.appplaceholdersync` unavailable.
- Existing placeholders may not update until rollback.

## Expected Still Works (verified)

| Check | Result |
|-------|--------|
| SSH / network | OK |
| `softwareupdate --list` | OK |
| App Store app launch | OK |
| **App Store free app install** | **OK (GUI-confirmed)** |
| `appstoreagent`, `amsaccountsd`, `fairplayd`, `installcoordinationd` | running, quiet |
| Audio stack | `audiomxd` / `audioaccessoryd` 0% CPU |

## Notes

- Do not batch with `appstoreagent`, CommerceKit labels, or Apple ID stack.
- Part of App Store **ecosystem trim**, not core install path.
- Future tweaker question: *“Show app placeholders from other Apple devices on this Mac?”* → default **no** on coding profile.