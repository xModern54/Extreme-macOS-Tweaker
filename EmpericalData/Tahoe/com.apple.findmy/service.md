# Find My Ecosystem — Disabled

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | Find My (Find My Mac, Find My Device, Offline Finding)       |
| Category      | icloud_account_apple_ecosystem                               |
| Risk Level    | 2 — disables a macOS feature but should not break boot       |

## What It Does

The Find My ecosystem enables Apple's device-finding infrastructure:

- **Find My Device**: remote locate, lock, and wipe via iCloud
- **Find My Mac**: Mac-specific locate/lock/erase functionality
- **Offline Finding** (searchpartyd/beaconingd): crowd-sourced BLE mesh network that locates devices even when offline, by leveraging nearby Apple devices
- **Find My locate agent**: user-level agent for locating friends, devices, and items

This is a **security feature** — it allows finding a lost/stolen Mac and remotely erasing it. On an experimental target machine this is not critical.

## Observed Cost (before disable)

| Process               | Domain   | RSS     |
|-----------------------|----------|---------|
| `findmylocateagent`   | gui      | 23 MB   |
| `searchpartyd`        | system   | 23 MB   |
| `findmybeaconingd`    | system   | 11.5 MB |
| `findmydeviced`       | system   | 10.7 MB |
| `FindMyMacd`          | system   | 4.1 MB  |
| **Total**             |          | **~72 MB** |

Plus demand-loaded agents that activate on events:
- `findmydevice-user-agent` (gui)
- `findmymacmessenger` (gui + system)
- `searchpartyuseragent` (gui)

## Launchd Labels

### System domain (5 labels)

| Label                                  | Binary                  | Purpose                                   |
|----------------------------------------|-------------------------|-------------------------------------------|
| `com.apple.icloud.findmydeviced`       | `findmydeviced`         | Find My Device daemon (locate/lock/wipe)  |
| `com.apple.findmy.findmybeaconingd`    | `findmybeaconingd`      | BLE beacon for offline finding network    |
| `com.apple.findmymacd`                 | `FindMyMacd`            | Find My Mac (remote locate/lock/erase)    |
| `com.apple.icloud.searchpartyd`        | `searchpartyd`          | Offline Finding (crowd-sourced BLE mesh)  |
| `com.apple.findmymacmessenger`         | `FindMyMacMessenger`    | Messages from Find My Mac (demand)        |

### GUI domain (4 labels)

| Label                                                    | Binary                    | Purpose                               |
|----------------------------------------------------------|---------------------------|---------------------------------------|
| `com.apple.findmy.findmylocateagent`                     | `findmylocateagent`       | User-level locate agent               |
| `com.apple.icloud.findmydeviced.findmydevice-user-agent` | `findmydevice-user-agent` | User-facing Find My Device (demand)   |
| `com.apple.findmymacmessenger`                            | `FindMyMacMessenger`      | User-level Find My Mac messenger      |
| `com.apple.icloud.searchpartyuseragent`                   | `searchpartyuseragent`    | User agent for offline finding        |

## Relationship to locationd

Find My services are **clients** of `locationd`. They use it to obtain device location. `locationd` does **not** depend on Find My — it continues to run normally without these services. No locationd errors were observed after disabling Find My.

## Disable

```bash
uid=$(id -u)

# GUI labels
gui_labels=(
  com.apple.findmy.findmylocateagent
  com.apple.icloud.findmydeviced.findmydevice-user-agent
  com.apple.findmymacmessenger
  com.apple.icloud.searchpartyuseragent
)
for label in "${gui_labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done

# System labels
sys_labels=(
  com.apple.icloud.findmydeviced
  com.apple.findmy.findmybeaconingd
  com.apple.findmymacd
  com.apple.icloud.searchpartyd
  com.apple.findmymacmessenger
)
for label in "${sys_labels[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)

# GUI labels
for label in \
  com.apple.findmy.findmylocateagent \
  com.apple.icloud.findmydeviced.findmydevice-user-agent \
  com.apple.findmymacmessenger \
  com.apple.icloud.searchpartyuseragent; do
  launchctl enable "gui/$uid/$label"
done

# System labels
for label in \
  com.apple.icloud.findmydeviced \
  com.apple.findmy.findmybeaconingd \
  com.apple.findmymacd \
  com.apple.icloud.searchpartyd \
  com.apple.findmymacmessenger; do
  sudo launchctl enable "system/$label"
done

sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Bootout all 9 labels (4 gui + 5 system) — all 5 active processes disappeared immediately.
2. No retry loops in logs after bootout.
3. 30-second delayed check — no processes returned.
4. Disabled all 9 labels.
5. Rebooted target.
6. SSH came back in ~11 seconds.
7. Post-reboot health: network OK, DNS OK, gateway OK, memory OK.
8. No Find My processes returned after reboot — all 5 confirmed gone.
9. No Find My-related log entries at all during boot (no errors, no warnings).
10. No locationd errors — it does not care about missing Find My clients.
11. `locationd`, `CoreLocationAgent`, `geod` all still running normally.
12. Process count: 357 (down from previous baselines).

**Verdict: safe to disable on experimental target.** No breakage observed. ~72 MB saved.

## Expected Breakage

- Cannot locate this Mac via iCloud Find My.
- Cannot remotely lock or erase this Mac.
- Mac will not participate in Apple's offline finding BLE mesh network.
- Find My app on other devices will not see this Mac.
- AirTag and Find My Items features may not work fully on this Mac.

## Notes

- This is a security feature. Re-enable before deploying the machine in untrusted environments.
- `locationd` is unaffected and continues to serve other clients (timezone, Wi-Fi region, Weather, Maps).
- The BLE beaconing was the most background-active component — it continuously broadcasts to participate in Apple's crowd-sourced finding network.
