# Continuity remainder off — `continuity-remainder-off`

## Basics

| Field         | Value                                                                 |
|---------------|-----------------------------------------------------------------------|
| Feature group | **continuity-remainder-off** — Handoff UI / Sidecar / companion tails |
| Profile       | no-Continuity coding target                                           |
| Risk Level    | **1–2** — ecosystem continuity; BT stack untouched                    |
| Verdict       | **keep disabled** on experimental coding target — headless PASS       |

## What It Does (disabled stack)

| Label | Role |
|-------|------|
| `com.apple.RapportUIAgent` | **Handoff** UI agent (pairs with `rapportd` — system `rapportd` already off) |
| `com.apple.sidecar-relay` | **Sidecar** iPad display relay |
| `com.apple.mediacontinuityd` | **Media continuity** (AirPlay/handoff media paths) |
| `com.apple.companiond` | **Apple Watch / companion** device bridge |
| `com.apple.ensemble` | **Device ensemble** / cross-device grouping |

All gui `LaunchAgents`, on-demand (all idle pre-disable).

## Already disabled (related, not in this batch)

| Label | Notes |
|-------|-------|
| `com.apple.rapportd` (system) | Handoff core — prior test |
| `com.apple.sharingd` | AirDrop/Handoff sharing — prior test |
| `com.apple.cmio.ContinuityCaptureAgent` | Continuity Camera — prior test |
| `com.apple.replicatord` | replication — prior test |

## Explicitly NOT disabled

`com.apple.BTServer.cloudpairing`, `bluetoothd`, `audioaccessoryd`, `audiomxd`, `coreaudiod`, `akd`, `accountsd`, `secd`, `securityd`, `trustd`, `transparencyd`, `cdpd`, keychain cloud labels, `softwareupdated*`, `mobileassetd`.

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.RapportUIAgent
  com.apple.sidecar-relay
  com.apple.mediacontinuityd
  com.apple.companiond
  com.apple.ensemble
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
labels=(
  com.apple.RapportUIAgent
  com.apple.sidecar-relay
  com.apple.mediacontinuityd
  com.apple.companiond
  com.apple.ensemble
)
for label in "${labels[@]}"; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result (2026-06-29, target `codexadmin` uid 502)

**Experiment:** `continuity-remainder-off` — 5 labels; all existed and enabled; clean reboot.

### Inventory

| Action | Count |
|--------|-------|
| **Touched** | **5** — all found, all enabled → disabled |
| **Skipped** | **0** |

### Headless

| Check | Result |
|-------|--------|
| SSH / network / DNS | **PASS** |
| 5 labels disabled, not running | **PASS** |
| 60s no respawn | **PASS** |
| `bluetoothd` + `cloudpairing` untouched | **PASS** |
| `coreaudiod` / `audiomxd` / `audioaccessoryd` idle | **PASS** |
| `akd` / `accountsd` / `secd` / `trustd` | **PASS** |
| `softwareupdate --list` | **PASS** |
| Keychain + local files | **PASS** |
| Safari + Terminal + Happ + Finder + Settings | **PASS** |
| Rollback | **not needed** |

### Logs

| Signal | Result |
|--------|--------|
| Continuity tail errors | **1** |
| Continuity failed lookup | **2** |
| Bluetooth/audio errors | boot noise; **no storm** |
| auth errors | functional; **no storm** |

### GUI

Pending user (Sidecar/Handoff dead expected).

## Expected Breakage

- Handoff UI, Sidecar, media continuity, Watch companion, ensemble grouping

## Expected Still Works

- Desktop, local apps, Bluetooth basic (`bluetoothd`), audio, network, keychain, `softwareupdate`

## Related

- `services/com.apple.rapportd/service.md` — core `rapportd` + AirPlay batch
- `services/com.apple.sharingd/service.md`