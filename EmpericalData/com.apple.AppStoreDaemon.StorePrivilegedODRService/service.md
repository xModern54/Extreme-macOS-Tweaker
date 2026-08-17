# On-Demand Resources privileged helper — `com.apple.AppStoreDaemon.StorePrivilegedODRService`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | App Store ODR (On-Demand Resources) root filesystem helper only     |
| Process       | `com.apple.AppStoreDaemon.StorePrivilegedODRService` (XPC)            |
| Binary        | `.../AppStoreDaemon.framework/Versions/A/XPCServices/com.apple.AppStoreDaemon.StorePrivilegedODRService.xpc/Contents/MacOS/com.apple.AppStoreDaemon.StorePrivilegedODRService` |
| Plist         | **No LaunchDaemon** — XPC bundle `Info.plist` under path above        |
| Domain        | `system` (XPCService, `ServiceType = System`)                         |
| Category      | `consumer_apps_media` — ODR asset packs, not core `.app` install      |
| Risk Level    | **2** — breaks ODR-tagged App Store apps; not boot-critical           |
| Profile       | **keep disabled** on coding-only / Minimal App Store target           |

## What It Does

Privileged **root** XPC helper for `appstoreagent`'s `ODRManager`:

- `ensureODRDirectoryExists`, `moveAssetPackAtPath`, `writeAssetPackMetadata`, `deleteAssetPackAtPath`
- Writes under `/System/Library/Caches/OnDemandResources`, `.../com.apple.appstore/ODR/`
- Mach: `com.apple.AppStoreDaemon.StorePrivilegedODRService`
- Client entitlement: `com.apple.private.store.privileged.odr`

**Only caller:** `appstoreagent` (no refs in `commerce`, `storedownloadd`, `storeassetd`, `installcoordinationd`).

**Not used for:** regular Mac App Store `.app` download/install, `softwareupdate`, Xcode SDK/platforms/CLT, StoreKit payment UI (`storeuid`).

`appstoreagent` ignores non-ODR installs: *"does not appear to support ODR"*.

**Sibling (do not confuse):** `com.apple.AppStoreDaemon.StorePrivilegedTaskService` — receipt/IAP privileged tasks, separate XPC.

## Observed Cost

| Metric | Value |
|--------|-------|
| RSS when running | ~7–8 MB |
| Spawn | on-demand via Mach IPC (`immediate reason = ipc (mach)`) |
| Target ODR cache | empty (`/private/var/db/ondemand`, `AssetPacks`) |

## Disable

```bash
label=com.apple.AppStoreDaemon.StorePrivilegedODRService
sudo launchctl bootout "system/$label" 2>/dev/null || true
sudo launchctl disable "system/$label"
```

**Post-reboot note:** on macOS 26.4 target, `disable` flag persisted but XPC **still spawned once at boot**. One extra bootout after reboot was required; after that, opening App Store did **not** respawn ODR.

Recommended apply pattern:

```bash
label=com.apple.AppStoreDaemon.StorePrivilegedODRService
sudo launchctl bootout "system/$label" 2>/dev/null || true
sudo launchctl disable "system/$label"
sudo shutdown -r now
# after SSH returns:
sudo launchctl bootout "system/$label" 2>/dev/null || true
```

## Rollback

```bash
sudo launchctl enable system/com.apple.AppStoreDaemon.StorePrivilegedODRService
# respawns on next ODR Mach lookup from appstoreagent; reboot for clean state
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Scope:** single system XPC label only. Protected stack not touched.

### Disable + reboot + post-reboot bootout

1. Pre-disable: ODR running ~7.7 MB; disable flag absent.
2. `bootout` + `disable` — process gone; protected stack quiet.
3. `softwareupdate --list` — OK before and after reboot.
4. Reboot — SSH ~25s; disable flag intact.
5. **Boot quirk:** ODR respawned ~7.8 MB despite disabled flag → `bootout` again → stayed absent.
6. 30s + 60s delayed checks — **no respawn** after post-reboot bootout.
7. `open -a "App Store"` — App Store + `appstoreagent` + `commerce` + `storeuid` spawned; **ODR absent**.
8. No ODR error/retry storm in log sample; no `StorePrivilegedODR` connection errors after bootout.

**Headless verdict: keep disabled** on coding target (pending GUI install/update confirmation).

### GUI (pending user)

- [ ] Update installed non-ODR app
- [ ] Install new free non-ODR app

## Expected Breakage

- ODR asset pack download/purge/maintenance for ODR-tagged App Store apps (mostly games).
- Post-install tagged content fetch; ODR repair paths in `appstoreagent`.
- `ODRDeveloperToolsClient` purge hooks for ODR bundles.

**Not expected to break (headless verified):** SSH/network, `softwareupdate --list`, App Store.app launch, `appstoreagent`/`commerce`/`storeuid` spawn.

## Notes

- Future tweaker question: *"Download extra game/content packs from App Store apps (ODR)?"* → default **no** on coding profile.
- Do not batch with `appstoreagent`, `storedownloadd`, `commerce`, `storeuid`, or Apple ID stack.
- Full GUI + ODR games profile → **KEEP** enabled.