# Bluetooth user layer / iCloud cloud pairing — `bluetoothuserd` (bluetoothuserd-off)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `com.apple.bluetoothuserd` only                               |
| Category      | `icloud` — per-user Bluetooth cloud sync / user notifications |
| Risk Level    | **2** — user-layer only; core `bluetoothd` untouched            |
| Profile       | **keep disabled on no-iCloud-BT-sync coding target**          |

**Headless validated.** No GUI tests in this experiment.

## What It Does (за что отвечает)

Per-user **Bluetooth user daemon** — not the radio stack. Complements system `bluetoothd` with cloud metadata, iCloud pairing hooks, and user notifications.

| Responsibility | Detail |
|----------------|--------|
| Cloud paired devices | CloudKit/KVS `com.apple.bluetooth.cloud.settings`, `CloudPairedDeviceRecords` |
| CloudPairingManager | IDS iCloud pairing notifications, cloud pairing enabled state |
| Darwin bridge | Listens `com.apple.bluetooth.daemonStarted`; posts `com.apple.bluetoothuser.cloudChanged` to `bluetoothd` |
| User notifications | Game controller connected, USB pairing complete, BT user alerts |
| Find My BT hooks | FindMyPair / FindMyUnpair (already moot: Find My stack disabled on target) |
| Nearby Biome stream | `BluetoothNearbyDevice` telemetry (not UWB `nearbyd`) |
| APS push | `com.apple.aps.bluetoothuserd` |

**Not touched:** `bluetoothd`, `WirelessRadioManager`, `BluetoothUIService`, `bluetoothaudiod`.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.bluetoothuserd` | gui | `bluetoothuserd` | `/System/Library/LaunchAgents/com.apple.bluetoothuserd.plist` |

**Binary:** `/usr/libexec/bluetoothuserd`

**Launch:** no `RunAtLoad` / no `KeepAlive` — on-demand via Mach IPC; also notify triggers (`daemonStarted`, KVS, IDS pairing, hostname, CK identity, cloud retry fetch).

**MachServices:**
- `com.apple.bluetoothuser.xpc`
- `com.apple.aps.bluetoothuserd`
- `com.apple.usernotifications.delegate.com.apple.bluetoothuserd.UserNotification`

## vs `bluetoothd`

| | `bluetoothd` | `bluetoothuserd` |
|---|-------------|------------------|
| Domain | `system` | `gui/<uid>` |
| Role | radio, HCI, classic/BLE pairing stack | per-user cloud sync, notifications |
| Lifecycle | `RunAtLoad` + `KeepAlive` | on-demand agent |
| Cloud pairing | via `cloudpaird` / `BTServer.cloudpairing` (already disabled) + listens `bluetoothuser.cloudChanged` | own `CloudPairingManager` + CloudKit records |

## Who Was Calling It (before disable)

| Source | Finding |
|--------|---------|
| Unified logs (7d before research) | **0** bluetoothuserd lines — idle |
| XPC clients at research time | endpoints active, `watching=0` — no connected clients |
| Boot chain | `bluetoothd` posts `daemonStarted` → userd resident after login (`runs=1`) |
| Context on target | `identityservicesd`, Find My, `audioaccessoryd`, `nearbyd`, `sharingd`, `rapportd` already disabled |

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `bluetoothuserd` | ~17 MB |

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
launchctl bootout "gui/$uid/com.apple.bluetoothuserd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.bluetoothuserd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.bluetoothuserd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-27 — experiment **bluetoothuserd-off**

**Before:** processes **303**, total RSS **5 322 848 KB**, `bluetoothuserd` running (~17 MB, pid 493).

1. Bootout/disable `gui/502/com.apple.bluetoothuserd` — gone immediately.
2. Clean-reboot prefs + reboot — SSH back ~21 s; prefs `0/0/0`.
3. **Post-reboot (headless):**
   - SSH: OK
   - Route: default via `en0`, gateway `192.168.1.1`
   - DNS: resolver via `en0`
   - `bluetoothuserd`: **not running**; disable flag intact; job **not loaded**
   - **Delayed 25 s:** no respawn, no crash loop
   - **Log storm:** 0 bluetoothuserd / bluetoothuser / cloudChanged / CloudPairingManager lines (5m window)
   - **Protected neighbors — still running, quiet:**

| Neighbor | Status | Log noise |
|----------|--------|-----------|
| `bluetoothd` | running (~35 MB) | **none** |
| `WirelessRadioManagerd` | running (~9 MB) | **none** |
| `BluetoothUIService` | not in ps (on-demand) | n/a |
| `bluetoothaudiod` | not running (idle) | n/a |
| `audioaccessoryd` / `BTServer.cloudpairing` | disabled (prior) | n/a |

4. **After metrics:** processes **278**, total RSS **4 561 600 KB** (~17 MB from `bluetoothuserd` removed; larger delta from fresh boot vs warm session)

**Verdict: keep disabled on coding experimental target.**

## Exact Breakage Notes (Empirically Verified in GUI)

| Broken / degraded | Detail |
|-------------------|--------|
| **GUI Bluetooth Device Pairing** | **CRITICAL: New Bluetooth devices/headphones fail to pair in GUI (spins infinitely during handshake). `bluetoothuserd` provides `com.apple.bluetoothuser.xpc` for pairing credentials/handshake!** |
| iCloud sync cloud-paired Bluetooth devices | CloudPairedDeviceRecords / KVS path gone |
| IDS/iCloud pairing notifications | `CloudPairingManager` IDS hooks inactive |
| Bluetooth user notifications | `UserNotification` delegate unavailable |

**Verdict: DO NOT DISABLE if GUI Bluetooth pairing for new devices/headphones is required. Keep enabled for full Bluetooth headset functionality.**

## Neighbors After Disable

| Component | Noise after disable + reboot |
|-----------|------------------------------|
| `bluetoothd` | running, **quiet** |
| `WirelessRadioManagerd` | running, **quiet** |
| `bluetoothaudiod` | idle (not loaded) |
| `audioaccessoryd` / `BTServer.cloudpairing` | remain disabled, unchanged |
| `nearbyd` / `sharingd` / `rapportd` | remain disabled, unchanged |
| `bluetoothuserd` | **gone**, no respawn |