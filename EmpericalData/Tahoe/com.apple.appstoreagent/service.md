# Mac App Store off — Stage A (`no-app-store-stage-a-off`)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **no-app-store-stage-a** — kill Mac App Store install/update path     |
| Profile       | Mac App Store off; **keep** `softwareupdate` / CLT / OS updates       |
| Category      | `consumer_apps_media`                                                 |
| Risk Level    | **3** — Mac App Store dead by design; protected install/DRM untouched |
| Verdict       | **keep disabled** for daemon trim; **not** full Store kill (GUI nuance) |

## What It Does (disabled stack)

Stage A removes the Mac App Store commerce/install UI and daemon layer while leaving OS Software Update, DRM install coordination, FairPlay, and Apple ID base stack enabled.

### GUI labels (`gui/<uid>`) — all disabled

| Label | Role |
|-------|------|
| `com.apple.appstoreagent` | App Store orchestrator / catalog / install |
| `com.apple.commerce` | CommerceKit backend |
| `com.apple.storedownloadd` | download bytes |
| `com.apple.storeaccountd` | CommerceKit account service |
| `com.apple.storeassetd` | update/asset observers |
| `com.apple.storelegacy` | legacy download queue / storeagent-xpc |
| `com.apple.storeuid` | payment/auth/StoreKit UI |
| `com.apple.appstorecomponentsd` | App Store Jet UI vitrine |
| `com.apple.storekitagent` | StoreKit IAP helper |

### System labels — all disabled

| Label | Role |
|-------|------|
| `com.apple.appstored` | system App Store helper (`_appstore`) |
| `com.apple.storereceiptinstaller` | receipt install |
| `com.apple.AppStoreDaemon.StorePrivilegedODRService` | ODR privileged filesystem |
| `com.apple.AppStoreDaemon.StorePrivilegedTaskService` | receipt/IAP privileged tasks |
| `com.apple.AppStoreDaemon.StoreAEService` | App Store quit AppleEvent helper (XPC) |

### Explicitly NOT disabled (Stage A)

`softwareupdated`, `mobile.softwareupdated`, `mobileassetd`, `suhelperd`, `installcoordinationd`, `installcoordination_proxy`, `fairplayd`, `fairplaydeviceidentityd`, `amsaccountsd`, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, audio stack.

### Already off before Stage A (not in this batch)

Ads (`amsengagementd`×3), placeholders, `amsondevicestoraged`, AssetCache×6, media stores, `managedappdistributionagent`, `SoftwareUpdateNotificationManager`.

## Observed Cost (before Stage A)

~**200 MB** warm when App Store + commerce stack running (appstoreagent, storeuid, appstorecomponentsd, storekitagent, commerce, store*, privileged XPC).

## Disable

```bash
uid=$(id -u)
gui_labels=(
  com.apple.appstoreagent
  com.apple.commerce
  com.apple.storedownloadd
  com.apple.storeaccountd
  com.apple.storeassetd
  com.apple.storelegacy
  com.apple.storeuid
  com.apple.appstorecomponentsd
  com.apple.storekitagent
)
sys_labels=(
  com.apple.appstored
  com.apple.storereceiptinstaller
  com.apple.AppStoreDaemon.StorePrivilegedODRService
  com.apple.AppStoreDaemon.StorePrivilegedTaskService
  com.apple.AppStoreDaemon.StoreAEService
)
for label in "${gui_labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
for label in "${sys_labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
sudo shutdown -r now
# post-reboot XPC quirk: optional bootout privileged XPC if respawned despite disable
for label in com.apple.AppStoreDaemon.StorePrivilegedODRService com.apple.AppStoreDaemon.StorePrivilegedTaskService; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
done
```

## Rollback (Stage A group)

```bash
uid=$(id -u)
gui_labels=(
  com.apple.appstoreagent
  com.apple.commerce
  com.apple.storedownloadd
  com.apple.storeaccountd
  com.apple.storeassetd
  com.apple.storelegacy
  com.apple.storeuid
  com.apple.appstorecomponentsd
  com.apple.storekitagent
)
sys_labels=(
  com.apple.appstored
  com.apple.storereceiptinstaller
  com.apple.AppStoreDaemon.StorePrivilegedODRService
  com.apple.AppStoreDaemon.StorePrivilegedTaskService
  com.apple.AppStoreDaemon.StoreAEService
)
for label in "${gui_labels[@]}"; do
  launchctl enable "gui/$uid/$label"
done
for label in "${sys_labels[@]}"; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Scope:** Stage A batch only. Install/DRM/auth/audio protected labels not touched.

### Pre-disable

~289 processes; ~4963 MB RSS sum; store stack warm ~200 MB (App Store session artifacts).

### Disable + clean reboot

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| All 9 gui disable flags intact | **PASS** |
| All 5 system disable flags intact | **PASS** |
| Store daemons absent (pgrep 60s) | **PASS** |
| No appstoreagent/commerce log error storm | **PASS** |
| `softwareupdate --list` | **PASS** |
| `mobileassetd` / `softwareupdated` / `suhelperd` running | **PASS** |
| `installcoordinationd` / `fairplayd` not disabled; on-demand at boot, kickstart OK | **PASS** |
| `amsaccountsd` / `akd` / `accountsd` / `secd` / `trustd` quiet | **PASS** |
| Audio stack 0% CPU idle | **PASS** |
| Keychain listable | **PASS** |
| Safari + Terminal launch | **PASS** |
| `open -a App Store` — GUI shell may open; **no** `appstoreagent`/commerce/storeuid | **PASS** (dead backend) |

**Post-reboot:** store daemon RSS **~0**; ~**200 MB** saved vs pre-disable warm store stack.

**Headless verdict: keep disabled** (Stage A daemon layer).

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| System Settings | **PASS** — no crash |
| App Store after Stage A only | **PARTIAL** — icons/vitrine partial; updates list failed |
| App Store after Stage B (`amsaccountsd` off) | **FULL FAIL (expected)** — «cannot connect», nothing loads |
| Updates tab | **FAIL (expected)** — unavailable |
| **New app install (Stage A era)** | user once reported working via `installcoordinationd` path; **moot after Stage B** |
| Existing installed apps | **PASS** |
| Xcode | **PASS** |

**Re-check with Store open (agent):** no `appstoreagent`/`commerce`/`storeuid`/`storedownloadd`; only `App Store.app` + `installcoordinationd` + `fairplayd` + `amsaccountsd`. Disable flags intact.

**Interpretation:** Stage A kills the **AppStoreDaemon/CommerceKit daemon layer** (~200 MB) and breaks **in-Store updates listing**, but **new app install can still work** via surviving `installcoordinationd` + `fairplayd` + `amsaccountsd` + in-process `App Store.app` logic. This is **not** a complete «Mac App Store off» without also trimming install coordination or blocking `App Store.app`.

## Expected Breakage (confirmed)

- In-App **Updates list** for installed App Store apps
- Catalog/update orchestration via `appstoreagent` (errors «failed to load updates»)
- ODR / privileged receipt paths (disabled)

## Expected Breakage (revised — NOT fully dead)

- **New free/paid app install may still work** while `installcoordinationd` + `fairplayd` + `amsaccountsd` remain enabled

## Expected Still Works (confirmed)

- `softwareupdate` / CLT / macOS update listing (CLI)
- System Settings / Apple Account UI
- Existing installed apps launch
- Local keychain / auth daemons
- Network / audio
- Partial App Store UI shell

## Notes

- **Stage C nuclear** (`installcoordinationd` + `fairplayd`) — see `services/com.apple.installcoordinationd/service.md` — **validated**: existing apps + DMG installs work; MAS/coordinated install path dead.
- Stage B (`amsaccountsd` + optional `fairplaydeviceidentityd` / `installcoordination_proxy`) — see `services/com.apple.amsaccountsd/service.md` — **headless PASS**.
- Do not batch-disable `installcoordinationd` / `fairplayd` in Stage A alone (explains surviving MAS installs before Stage C).
- Peripheral App Store trims remain in their own service cards.