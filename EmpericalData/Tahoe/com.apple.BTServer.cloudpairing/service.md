# Bluetooth cloud pairing / audio accessories — `BTServer.cloudpairing` (BTServer-cloudpairing-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `BTServer.cloudpairing` only (`audioaccessoryd`)              |
| Category      | Bluetooth cloud pairing / Apple audio accessories disabled    |
| Risk Level    | **2–3** — AirPods/iCloud BT sync layer; core BT stack untouched |
| Profile       | **keep enabled** — required to keep `audiomxd` idle (CPU loop if off) |

**GUI-confirmed:** Bluetooth still works after disable — user verified BT not broken.

## What It Does (за что отвечает)

Per-user **audio accessory / Bluetooth cloud pairing** daemon — launch label `com.apple.BTServer.cloudpairing`, plist `com.apple.cloudpaird.plist`, process **`audioaccessoryd`**.

| Responsibility | Detail |
|----------------|--------|
| iCloud BT pairing sync | ProtectedCloudStorage `BluetoothCloudPairing` / Manatee |
| AirPods / audio accessories | `AudioAccessoryServices`, `BluetoothCloudServices`, auto-switch, magic pairing |
| Nearby audio discovery | BLE `NearbyAudioAccessory` |
| iCloud Pairing IDS | `com.apple.private.alloy.icloudpairing` |
| Hearing / accessory UI | `HearingModeService`, audio accessory user notifications |

**Not touched:** `bluetoothd`, `bluetoothuserd`, `nearbyd`, `rapportd`, `sharingd`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.BTServer.cloudpairing` | gui | `audioaccessoryd` | `/System/Library/LaunchAgents/com.apple.cloudpaird.plist` |

**Binary:** `/System/Library/CoreServices/audioaccessoryd`

**Launch:** `RunAtLoad=true`; Mach IPC bootstrap.

Distinct from **`bluetoothd`** (radio/pairing stack). User BT keypad pairing uses `bluetoothd`, not this daemon.

## Who Was Calling It (before disable)

| Source | Finding |
|--------|---------|
| Unified logs (30m before) | **0** audioaccessory/cloudpair/BluetoothCloud lines — idle |
| Boot | `RunAtLoad=true` at login |
| Context | `nearbyd`, `sharingd`, `rapportd` already disabled; `audioaccessoryd` ran independently |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `audioaccessoryd` | ~32 MB |

## Clean Reboot (no app restore)

```bash
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
defaults write -g NSQuitAlwaysKeepsWindows -bool false
sudo shutdown -r now
```

## Disable (gui only)

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.BTServer.cloudpairing" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.BTServer.cloudpairing"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.BTServer.cloudpairing"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-23 — experiment **BTServer-cloudpairing-off**

**Context:** `nearbyd`, `sharingd`, `rapportd` already disabled. User previously GUI-confirmed BT keypad pairing works without `nearbyd`.

**Before:** processes **281**, total RSS **5146 MB**, `audioaccessoryd` running (~32 MB).

1. Clean-reboot prefs + bootout/disable `gui/502/com.apple.BTServer.cloudpairing` — gone immediately.
2. Reboot — SSH back ~18 s; `TALLogoutSavesState=0`, `LoginwindowLaunchesRelaunchApps=0`.
3. **Post-reboot (headless, no GUI tests):**
   - SSH: OK
   - Route: default via `en0`, gateway present
   - `audioaccessoryd`: **not running**; disable flag intact; job not loaded
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 audioaccessory/cloudpair/BluetoothCloud lines; 0 error/fail/retry
   - **Protected neighbors — still running/up, quiet:**

| Neighbor | Status | Log noise |
|----------|--------|-----------|
| `bluetoothd` | running (~36 MB) | **none** |
| `bluetoothuserd` | running (~17 MB) | **none** |
| `WirelessRadioManagerd` | running (~9 MB) | **none** |
| `nearbyd` | disabled (prior) | n/a |
| `sharingd` | disabled (prior) | n/a |
| `rapportd` | disabled (prior) | n/a |

4. **After metrics:** processes **286**, total RSS **5132 MB** (~32 MB from `audioaccessoryd` removed)
5. **Post-test (GUI, user-confirmed):** **Bluetooth not broken** — BT stack works after `BTServer-cloudpairing-off` (same as keypad pairing validation after `nearbyd-off`).

**Verdict (2026-06-23 off-test):** BT keypad OK without this daemon, but see rollback below.

### Rollback — 2026-06-27 (`cloudpairing-on` / audiomxd CPU fix)

**Reason:** With `audioaccessoryd` off, `audiomxd` burned ~70–84% CPU in `MXAudioAccessoryServices handleServerDeath` → `initializeAudioAccessoryConnection` retry loop; collateral `launchd` ~30%, `configd` ~19%. Disabling `audiomxd` is **not** viable — **GUI: all sound dies immediately**.

**Rollback commands:**

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.BTServer.cloudpairing"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.cloudpaird.plist
```

**Post-rollback (45s watch):**

| Process | CPU | RSS |
|---------|-----|-----|
| `audioaccessoryd` | **0%** | ~30 MB |
| `audiomxd` | **0%** | ~16 MB |
| `launchd` | **0%** | ~25 MB |
| `configd` | **0%** | ~13 MB |

**Verdict: keep enabled on this target.** Cost ~30 MB RAM; prevents audio stack CPU storm. Core BT keypad still OK without `nearbyd`/`bluetoothuserd` off states unchanged.

## Exact Breakage Notes (headless + GUI-confirmed BT OK)

| Broken | Detail |
|--------|--------|
| iCloud sync of Bluetooth pairings | Cloud pairing / Manatee path gone |
| AirPods magic pairing / auto-switch | `AudioAccessoryServices` / cloud services down |
| Nearby audio accessory discovery | BLE NearbyAudioAccessory discovery inactive |
| AirPods/audio accessory notifications | Accessory notification delegates unavailable |
| HearingModeService / AirPods hearing modes | Mach endpoint owned by `audioaccessoryd` |

**Does NOT break (verified):** core Bluetooth — **GUI-confirmed** BT not broken after this disable; manual pairing via `bluetoothd` (keyboard/mouse/keypad) OK. Headless: `bluetoothd`/`bluetoothuserd`/`WirelessRadioManagerd` running quiet.

**Not broken (verified headless):** SSH; core Bluetooth stack processes; `WirelessRadioManagerd`.

## Neighbors After Disable

| Component | Noise after disable + reboot |
|-----------|------------------------------|
| `bluetoothd` / `bluetoothuserd` | running, **quiet** |
| `WirelessRadioManagerd` | running, **quiet** |
| `nearbyd` / `sharingd` / `rapportd` | remain disabled, unchanged |
| `audioaccessoryd` | **gone**, no respawn |

## Notes

- Off-test showed core BT keypad OK, but **`audiomxd` requires this daemon** to avoid reconnect CPU loop.
- `audiomxd` itself is **protected** (sound dies if disabled) — see `services/com.apple.audiomxd/service.md`.
- Re-test manual BT pairing after any future disable experiments.