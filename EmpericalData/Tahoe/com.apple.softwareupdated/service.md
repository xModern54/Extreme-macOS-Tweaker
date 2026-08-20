# Software Update — Full Off (Variant B)

## In Plain Terms

**`softwareupdated`** — демон проверки обновлений macOS/CLT. **GUI «автопроверка off» и `schedule off` (Variant A) не убирают процессы на старте** — демоны всё равно поднимаются. **Variant C (shim/plist-костыли) отвергнут** — слишком сложно, на старте всё равно будил `mobileassetd`. **Текущий профиль: Variant B** — три `launchctl disable`, без доп. файлов; ~39 MB SU-стека на старте **нет**, ручной `softwareupdate` **мёртв** до rollback.

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | macOS Software Update background check + install helpers     |
| Category      | `core_macos` / `developer_tooling`                           |
| Risk Level    | **3** — updates broken until rollback                        |
| Status        | **Variant B active** on target (2026-06-29)                  |
| Tweaker profile | `updates-off-full`                                           |

## What It Does

Apple Software Update stack on macOS:

| Label | Binary | Role |
|-------|--------|------|
| `com.apple.softwareupdated` | `Software Update.app/.../softwareupdated` | Main daemon: background catalog scan, MSU controller, install orchestration |
| `com.apple.mobile.softwareupdated` | `MobileSoftwareUpdate.framework/.../softwareupdated` | MobileSoftwareUpdate support; `RunAtLoad` |
| `com.apple.suhelperd` | `Software Update.app/.../suhelperd` | On-demand privileged install helper |

**Background check triggers** (`com.apple.softwareupdated.plist`):

| Trigger | Scheduler | Interval / event |
|---------|-----------|------------------|
| `com.apple.SoftwareUpdate.Activity` | `dasd` via `UserEventAgent` | **21600 s (6 h)**, network, PowerNap |
| `com.apple.OSUpdate.PeriodicAutoUpdateActions` | `dasd` | **21600 s**, grace 1800 s |
| `ManualBackgroundTrigger` | notifyd | `com.apple.SoftwareUpdate.TriggerBackgroundCheck` |
| `CheckForCatalogChange` | notifyd | catalog change |

**Related (not disabled in Variant B):**

| Label | Role |
|-------|------|
| `com.apple.mobileassetd` | Asset catalog/download; still running (~48 MB) |
| `com.apple.MobileSoftwareUpdate.CleanupPreparePathService` | On-demand XPC |
| `com.apple.SoftwareUpdateNotificationManager` | GUI notifications (already disabled on target) |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `com.apple.softwareupdated` | ~22 MB |
| `com.apple.mobile.softwareupdated` | ~12 MB |
| `com.apple.suhelperd` | ~5 MB (on-demand) |
| **Variant B core** | **~39 MB** |

## Disable (Variant B)

**Repo script:** `scripts/softwareupdate-variant-b-apply.sh` (also removes any leftover Variant C mactweaker plists).

```bash
labels=(
  com.apple.softwareupdated
  com.apple.mobile.softwareupdated
  com.apple.suhelperd
)
for label in "${labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

Optional bootout of on-demand XPC if visible after disable:

```bash
sudo launchctl bootout system/com.apple.MobileSoftwareUpdate.CleanupPreparePathService 2>/dev/null || true
```

**Not included:** `com.apple.mobileassetd` (broader asset pipeline).

## Rollback

**Repo script:** `scripts/softwareupdate-variant-b-rollback.sh`

```bash
for label in com.apple.softwareupdated com.apple.mobile.softwareupdated com.apple.suhelperd; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

Before manual update after rollback:

```bash
softwareupdate --list
```

## Test Result

**2026-06-29 — Variant B (initial)**

| Check | Result |
|-------|--------|
| Reboot persistence (+90s) | PASS — **no** `softwareupdated` / `suhelperd` processes |
| `SoftwareUpdate.Activity` logs | PASS — **no registrations** since boot |
| `launchctl print-disabled` | PASS — all 3 labels disabled |
| SSH / Wi‑Fi / route | PASS |
| `mobileassetd` | Still running (intentional) |
| `softwareupdate --list` | **Hangs** — expected |
| GUI background activity | PASS — user confirmed gone |

**2026-06-29 — Variant C removed → Variant B restored**

| Check | Result |
|-------|--------|
| mactweaker plists / boot hook | **Removed** from `/Library/LaunchDaemons/` |
| Variant C rescue scripts | **Removed** (`swap-softwareupdated-override.sh`, `ensure-shims`) |
| Reboot (+14s) | PASS — **no** SU processes |
| All 3 Apple labels disabled | PASS |
| SSH / route | PASS |

## Expected Breakage

- Background and scheduled update **checks stop**
- `softwareupdate --list` / `--install` **fail or hang** until rollback
- System Settings → Software Update may error or show stale data
- `mobileassetd` may still run (~48 MB); separate research target

Should **not** affect: SSH, Git, networking, normal app launch.

## Notes

### Variant matrix (decision)

| Variant | What | Startup SU RAM | Manual updates | Verdict |
|---------|------|----------------|----------------|---------|
| **A** | GUI / `schedule off` | **Still there** | Works | **Rejected** — не отключает автопроверку на старте |
| **B** | `launchctl disable` 3 labels | **Gone** (~39 MB saved) | Broken | **Active** — coding target |
| **C** | shims + boot hook | **Still there** (`mobileassetd` wake) | Works | **Rejected** — блот без пропорциональной пользы |

### Future tweaker

- *No software updates on this Mac?* → **Variant B** (`updates-off-full`)
- *Need updates?* → rollback B, accept Apple defaults
- *Further RAM from assets?* → research `mobileassetd` separately (risk 3)