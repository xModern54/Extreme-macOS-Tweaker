# Apple Media Services account — `com.apple.amsaccountsd` (Stage B zero-commerce)

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **no-app-store-stage-b-zero-commerce** — AMS account/token layer      |
| Process       | `amsaccountsd`                                                        |
| Binary        | `/System/Library/PrivateFrameworks/AppleMediaServices.framework/Resources/amsaccountsd` |
| Plist         | `/System/Library/LaunchAgents/com.apple.amsaccountsd.plist`           |
| Domain        | `gui/<uid>`                                                           |
| Category      | `consumer_apps_media` — AMS commerce/account, not base Apple ID     |
| Risk Level    | **2** — media/Store account surfaces; base `akd`/`accountsd` kept   |
| Verdict       | **keep disabled** on coding target (headless PASS; GUI pending)     |

## What It Does

Apple Media Services (AMS) per-user account daemon:

- AMS tokens, account cache, storefront/eligibility notifications
- Tied to App Store / Apple TV / Music / Books commerce account flows
- **Not** the base Apple ID stack (`akd`, `accountsd`, `secd`, `trustd`)

## Stage B batch (with Stage A already off)

### Disabled in this test

| Label | Domain | Notes |
|-------|--------|-------|
| `com.apple.amsaccountsd` | gui | **primary Stage B target** |
| `com.apple.fairplaydeviceidentityd` | system | optional; was enabled → disabled |
| `com.apple.installcoordination_proxy` | system | optional; was enabled → disabled |

### Left enabled (explicit)

`installcoordinationd`, `fairplayd`, `akd`, `accountsd`, `secd`, `trustd`, `softwareupdated*`, `mobileassetd`, `suhelperd`, audio, `bird`, `cloudd`, Stage A store labels remain disabled.

## Observed Cost

| Metric | Before disable |
|--------|----------------|
| RSS warm | ~32–36 MB |
| CPU idle | 0% |

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.amsaccountsd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.amsaccountsd"
# optional (if present/enabled):
sudo launchctl bootout system/com.apple.fairplaydeviceidentityd 2>/dev/null || true
sudo launchctl disable system/com.apple.fairplaydeviceidentityd
sudo launchctl bootout system/com.apple.installcoordination_proxy 2>/dev/null || true
sudo launchctl disable system/com.apple.installcoordination_proxy
```

## Rollback (Stage B group)

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.amsaccountsd"
sudo launchctl enable system/com.apple.fairplaydeviceidentityd
sudo launchctl enable system/com.apple.installcoordination_proxy
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Prerequisite:** Stage A (`no-app-store-stage-a-off`) already disabled and validated.

### Disable + clean reboot

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| Stage A labels still disabled | **PASS** |
| `amsaccountsd` not running | **PASS** |
| `fairplaydeviceidentityd` / `installcoordination_proxy` disabled, not running | **PASS** |
| 60s no respawn | **PASS** |
| No ams/accountsd/akd/trustd log error storm | **PASS** |
| `softwareupdate --list` | **PASS** |
| `softwareupdated` / `mobileassetd` / `suhelperd` running | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` quiet | **PASS** |
| `bird` / `cloudd` untouched | **PASS** |
| Keychain accessible | **PASS** |
| Safari + Terminal launch | **PASS** |
| `open -a App Store` — shell only; no `amsaccountsd`/store daemons | **PASS** |
| `installcoordinationd` / `fairplayd` on-demand idle at boot (not disabled) | **PASS** |
| Audio 0% CPU idle | **PASS** |

**Savings:** ~32 MB (`amsaccountsd` absent).

**Verdict: keep disabled** (Stage B + cumulative Stage A).

### GUI-confirmed (user, 2026-06-29)

| Check | Result |
|-------|--------|
| Settings | **PASS** — opens, no crash |
| App Store | **PASS (dead expected)** — «cannot connect», catalog/icons do not load (worse than Stage A-only partial UI; **expected** after `amsaccountsd` off) |
| Previously installed apps | **PASS** — launch normally |
| One other app won't launch | **unknown** — user not sure related to Store trim |
| Xcode | **PASS** — launches fine |
| Desktop / network / keychain feel | **PASS** — «без этого всё нормально» |

**Interpretation:** Stage B removed AMS connectivity layer; App Store UI shell opens but cannot reach catalog/account backend. Coding workflow unaffected.

## Expected Breakage

- AMS account/token refresh for media/Store commerce
- Apple media entitlement/status checks via AMS
- Store receipts/account surfaces (Store already dead from Stage A)

## Expected Still Works

- Base Apple ID via `akd` / `accountsd`
- `softwareupdate` / CLT / macOS updates
- Local keychain, desktop, network, audio
- `installcoordinationd` / `fairplayd` (enabled at Stage B; **disabled in Stage C** — see `services/com.apple.installcoordinationd/service.md`)

## Notes

- Stage B builds on Stage A; rollback Stage B alone re-enables AMS without restoring Store daemons.
- Full Store rollback requires Stage A rollback group in `services/com.apple.appstoreagent/service.md`.
- Stage C (`installcoordinationd` + `fairplayd`) validated separately — nuclear, target-only.