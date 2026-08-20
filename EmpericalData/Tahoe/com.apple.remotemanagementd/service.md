# MDM / Remote Management Stack

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | MDM plumbing: `remotemanagementd` + subscribers, `mdmclient`, `managedappdistributiond` |
| Category      | `auth_security` / device management                            |
| Risk Level    | 1–2 — safe when MDM enrollment is No (verified before test)    |

## What It Does

Apple device management infrastructure for MDM/DEP enrollment, configuration profiles, and managed app distribution. On an **unenrolled** Mac these daemons still run idle plumbing.

| Component | Label | Role |
|-----------|-------|------|
| Remote Management daemon | `com.apple.remotemanagementd` | Core RM daemon; spawns subscriber XPC services |
| RM subscribers | *(no separate launchd labels)* | Migration, ScreenSharing, SoftwareUpdate, ManagedPreferences, ManagedApps, Security, etc. |
| MDM client (system) | `com.apple.mdmclient.daemon` | MDM daemon channel |
| MDM boot hook | `com.apple.mdmclient.daemon.runatboot` | MDM run-at-boot helper |
| MDM client (user) | `com.apple.mdmclient.agent` | Per-user MDM agent |
| Managed app dist (system) | `com.apple.managedappdistributiond` | Managed/VPP app distribution daemon |
| Managed app dist (user) | `com.apple.managedappdistributionagent` | Per-user managed app agent |
| RM GUI agent | `com.apple.RemoteManagementAgent` | Remote Management user agent |
| Device management events | `com.apple.devicemanagementclient.managedeventsd` | Managed device events daemon |

**Note:** There are no separate `com.apple.remotemanagement.*` launchd labels — subscribers are XPC children of `remotemanagementd` and disappear when it is disabled.

Pre-test enrollment check:

```text
profiles status -type enrollment
  Enrolled via DEP: No
  MDM enrollment: No
```

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `managedappdistributiond` | ~23 MB |
| `remotemanagementd` | ~14 MB |
| 11× RM `*Subscriber` XPC | ~10–11 MB each |
| `mdmclient` | 0 (idle / not running at capture) |
| **Total RSS** | **~161 MB** |

## Launchd Labels (8 disabled)

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.remotemanagementd` | `/System/Library/LaunchDaemons/com.apple.remotemanagementd.plist` | system |
| `com.apple.managedappdistributiond` | `/System/Library/LaunchDaemons/com.apple.managedappdistributiond.plist` | system |
| `com.apple.mdmclient.daemon` | `/System/Library/LaunchDaemons/com.apple.mdmclient.daemon.plist` | system |
| `com.apple.mdmclient.daemon.runatboot` | `/System/Library/LaunchDaemons/com.apple.mdmclient.daemon.runatboot.plist` | system |
| `com.apple.devicemanagementclient.managedeventsd` | `/System/Library/LaunchDaemons/com.apple.devicemanagementclient.managedeventsd.plist` | system |
| `com.apple.managedappdistributionagent` | `/System/Library/LaunchAgents/com.apple.managedappdistributionagent.plist` | gui |
| `com.apple.mdmclient.agent` | `/System/Library/LaunchAgents/com.apple.mdmclient.agent.plist` | gui |
| `com.apple.RemoteManagementAgent` | `/System/Library/LaunchAgents/com.apple.RemoteManagementAgent.plist` | gui |

## Disable

```bash
uid=$(id -u)
labels_system=(
  com.apple.managedappdistributiond
  com.apple.mdmclient.daemon
  com.apple.mdmclient.daemon.runatboot
  com.apple.remotemanagementd
  com.apple.devicemanagementclient.managedeventsd
)
for label in "${labels_system[@]}"; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
labels_gui=(
  com.apple.managedappdistributionagent
  com.apple.mdmclient.agent
  com.apple.RemoteManagementAgent
)
for label in "${labels_gui[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in com.apple.managedappdistributiond com.apple.mdmclient.daemon com.apple.mdmclient.daemon.runatboot com.apple.remotemanagementd com.apple.devicemanagementclient.managedeventsd; do
  sudo launchctl enable "system/$label"
done
for label in com.apple.managedappdistributionagent com.apple.mdmclient.agent com.apple.RemoteManagementAgent; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `managedappdistributiond` + `remotemanagementd` + 11 subscriber XPC processes running (~161 MB RSS). `mdmclient` not running.
2. Bootout/disable all 8 labels — all RM/MDM/managed-app processes disappeared immediately (including subscribers).
3. 30-second delayed check — none returned.
4. Reboot — SSH back ~23 seconds.
5. Post-reboot: no MDM/RM processes; all 8 disable flags intact.
6. 45-second delayed check — still clean.
7. `profiles status -type enrollment` still No/No.
8. Process count: ~331 → 315 (−16).
9. Health: gateway, Wi-Fi, memory pressure OK.

**Verdict: safe to disable on unenrolled coding experimental target.**

### Cross-stack note (2026-06-20)

With MDM/RM disabled as part of the cumulative experimental stack, user later confirmed **Apple Account sign-in**, **App Store**, and **App Store app downloads** still work. See `services/com.apple.amsengagementd/service.md` for full stack validation.

## Expected Breakage

- MDM/DEP enrollment and profile delivery will not work (already not enrolled).
- Managed app distribution / VPP install plumbing disabled.
- Remote Management subscriber channels (managed preferences, software update policy, etc.) gone.

No observed impact on SSH, Wi-Fi, boot, or GUI on unenrolled Mac.

## Notes

- `com.apple.mdmclient.daemon.runatboot` was already in disabled list from earlier session before this group test; re-disabled with the bundle.
- Re-enable before enrolling Mac in any MDM/ABM program.
- Related but **not** disabled: Screen Sharing agents (`com.apple.screensharing.*`) — separate feature group.