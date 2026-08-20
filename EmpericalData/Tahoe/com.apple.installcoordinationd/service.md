# Nuclear install/DRM layer — Stage C (`stage-c-nuclear-store-drm-install-off`)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **stage-c-nuclear-store-drm-install-off** — shared install + FairPlay DRM |
| Profile       | **Target-only / NOT production** — builds on Stage A+B               |
| Processes     | `installcoordinationd`, `fairplayd`                                   |
| Category      | `consumer_apps_media` + `auth_security` (DRM only)                   |
| Risk Level    | **4** — coordinated install + FairPlay; recovery plan required       |
| Verdict       | **validated on target** — surprisingly clean; keep disabled only on experimental coding target |

## What It Does

### `com.apple.installcoordinationd` (system)

- Coordinates app install/uninstall across Mac App Store, MDM, and other install paths
- Owns `/private/var/db/installcoordinationd` state
- Survived Stage A+B as the last shared install coordinator

### `com.apple.fairplayd` (system, on-demand)

- FairPlay DRM daemon (Mach service `com.apple.fairplayd`)
- Receipt validation, protected media, Arcade-related DRM
- Plist has `KeepAlive` → `Crashed` (may resist disable; **did not respawn** on this test)

### Already disabled before Stage C (do not re-enable here)

**Stage A** — App Store daemon layer (`appstoreagent`, `commerce`, `store*`, privileged Store XPC).  
**Stage B** — `amsaccountsd`, `fairplaydeviceidentityd`, `installcoordination_proxy`.

## Observed Cost

| Process | RSS idle (warm) |
|---------|-----------------|
| `fairplayd` | ~25 MB |
| `installcoordinationd` | on-demand; absent at idle after Stage C |

**Savings:** ~25 MB idle (`fairplayd` absent). `installcoordinationd` not warm at idle.

## Disable

**Prerequisite:** Stage A (`no-app-store-stage-a-off`) + Stage B (`amsaccountsd` batch) already disabled and validated.

```bash
labels=(
  com.apple.installcoordinationd
  com.apple.fairplayd
)
for label in "${labels[@]}"; do
  echo "== disable system/$label"
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
sudo launchctl print-disabled system 2>/dev/null | egrep -i 'installcoordinationd|fairplayd'
```

## Rollback (Stage C only)

Does **not** re-enable Stage A/B labels.

```bash
sudo launchctl enable system/com.apple.installcoordinationd
sudo launchctl enable system/com.apple.fairplayd
sudo shutdown -r now
```

Full Store restore requires Stage A rollback in `services/com.apple.appstoreagent/service.md` and optionally Stage B in `services/com.apple.amsaccountsd/service.md`.

## Explicitly NOT touched

`softwareupdated`, `mobile.softwareupdated`, `mobileassetd`, `suhelperd`, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, `syspolicyd`, `amfid`, `tccd`, audio stack, network stack.

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `stage-c-nuclear-store-drm-install-off` — disable only `installcoordinationd` + `fairplayd`; clean reboot, no app restore.

### Disable + reboot

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| Stage A labels still disabled | **PASS** |
| Stage B labels still disabled | **PASS** |
| `installcoordinationd` disabled, not running | **PASS** |
| `fairplayd` disabled, not running | **PASS** |
| `fairplayd` stayed disabled after reboot | **PASS** — no respawn/crash loop (~90s+ observation) |
| No log storm (ic/fp/trustd/syspolicyd/amfid) | **PASS** |
| `softwareupdate --list` | **PASS** — CLT + macOS updates listed |
| `softwareupdated` / `mobileassetd` / `suhelperd` quiet | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` quiet | **PASS** |
| Keychain accessible | **PASS** |
| Safari + Terminal launch | **PASS** |
| Xcode launch | **PASS** |
| Happ + other installed apps launch | **PASS** |
| MAS receipt apps launch (Xcode, Happ, Telegram, Speedtest, Passepartout) | **PASS** |
| Audio stack idle | **PASS** |
| Settings opens | **PASS** |
| Software Update UI | **PASS** — opens or soft-fails without crash |
| App Store | **PASS (dead expected)** — catalog/install dead since Stage B |
| **DMG install** (non-MAS) | **PASS** — user-confirmed installed DMGs still install |
| Rollback | **not needed** |

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| All apps open | **PASS** — «все норм, все приложения открываются» |
| DMG installs | **PASS** — already-installed workflow; DMG-based installs work |
| Desktop / network / keychain | **PASS** |

### Log audit (post-disable)

| Signal | Count / note |
|--------|----------------|
| `installcoordinationd` / `fairplayd` process errors since disable | **1** (pre-disable XPC disconnect) |
| `failed lookup: com.apple.fairplayd` | **3** at login — Music + AMPLibraryAgent; then silent |
| `failed lookup: installcoordinationd` | **0** |
| fairplay/ic mentions while idle (60s) | **0** |
| `syspolicyd` error burst | one-shot Gatekeeper noise on app launch — **not** Stage C loop |
| Store / StoreKit errors | expected from Stage A (`storekitagent` dead) — e.g. Passepartout IAP XPC fail; app still runs |

**Interpretation:** No log storm. Protected security/update stack unaffected. Breakage is **feature-level** (MAS catalog, IAP, coordinated/MDM installs, FairPlay media), not desktop stability.

## Expected Breakage (confirmed or likely)

- Mac App Store catalog/install/update — **dead** (Stage A+B; unchanged)
- StoreKit IAP / transaction refresh — **broken** (`storekitagent` off; Passepartout logs XPC fail)
- Coordinated MAS/MDM remote installs — **broken** (`installcoordinationd` off)
- Arcade / FairPlay-protected streaming — **likely dead** (not retested)
- Receipt validation on **new** MAS installs — **likely broken** (not retested; existing apps launch)

## Expected Breakage (NOT observed on this target)

- Launch of **already installed** apps (including MAS receipt apps)
- **DMG-based** local installs
- `softwareupdate` CLI / OS update path
- Desktop GUI, SSH, network, keychain, Xcode, Safari, Terminal

## Expected Still Works (confirmed)

- SSH, Wi-Fi, DNS, default route
- `softwareupdate --list` and Software Update UI
- System Settings
- Local keychain / base auth (`accountsd`, `secd`, `trustd`)
- Non-DRM and already-installed MAS apps
- DMG install path
- Audio idle

## Notes

- **Surprise:** Stage C is cleaner than risk-4 label suggested for a coding-only target with Store already dead. Main value is blocking coordinated install/DRM paths and saving ~25 MB `fairplayd`.
- `fairplayd` `KeepAlive Crashed` did **not** cause respawn after `launchctl disable` + reboot on macOS 26.4.1.
- Stage A doc said new MAS installs could work via `installcoordinationd` + `fairplayd`; **after Stage C that path is gone**. DMG/direct install still works.
- Do not use this profile on production machines.
- Cumulative no-App-Store stack: Stage A → Stage B → Stage C. Roll back in reverse order if needed.

## Related cards

- Stage A: `services/com.apple.appstoreagent/service.md`
- Stage B: `services/com.apple.amsaccountsd/service.md`