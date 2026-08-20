# Idle consumer leftovers batch — gist-list agents still enabled

## Basics

| Field         | Value |
|---------------|-------|
| Feature group | Idle consumer leftovers (News/Tips/Maps/Screen Sharing/FollowUp/…) |
| Main label    | `com.apple.followupd` (batch anchor; only process running pre-disable) |
| Category      | consumer_leftovers |
| Risk Level    | 1–2 |
| Verdict       | **keep disabled** on coding target |

## What It Does

Batch of launchd agents that were still **enabled** after earlier MacTweaker waves (cross-check vs common “disable bloat” gist lists). Almost all were **idle** (no process); only `followupd` was running (~6 MB).

Not included (separate / protected / higher risk):

```text
universalaccessd          — DO NOT
quicklook*                — separate candidate (alive, useful-ish)
BiomeAgent / biomed       — risk 3 separate wave
protectedcloudstorage.*   — iCloud key material
security.cloudkeychainproxy3 — iCloud Keychain proxy
dhcp6d                    — left alone (network edge case)
```

## Labels disabled (this wave)

### GUI + user (`gui/$uid` and `user/$uid`)

```text
com.apple.accessibility.MotionTrackingAgent
com.apple.cloudpaird
com.apple.familycontrols.useragent
com.apple.followupd
com.apple.iCloudUserNotifications
com.apple.imautomatichistorydeletionagent
com.apple.intelligenceflowd
com.apple.intelligencecontextd
com.apple.Maps.pushdaemon
com.apple.maps.mapssyncd
com.apple.maps.destinationd
com.apple.mediastream.mstreamd
com.apple.naturallanguaged
com.apple.newsd
com.apple.progressd
com.apple.screensharing.agent
com.apple.screensharing.menuextra
com.apple.SSInvitationAgent
com.apple.sidecar-hid-relay
com.apple.tipsd
com.apple.videosubscriptionsd
com.apple.watchlistd
```

### System

```text
com.apple.screensharing
com.apple.familycontrols
com.apple.ftp-proxy
```

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.accessibility.MotionTrackingAgent
  com.apple.cloudpaird
  com.apple.familycontrols.useragent
  com.apple.followupd
  com.apple.iCloudUserNotifications
  com.apple.imautomatichistorydeletionagent
  com.apple.intelligenceflowd
  com.apple.intelligencecontextd
  com.apple.Maps.pushdaemon
  com.apple.maps.mapssyncd
  com.apple.maps.destinationd
  com.apple.mediastream.mstreamd
  com.apple.naturallanguaged
  com.apple.newsd
  com.apple.progressd
  com.apple.screensharing.agent
  com.apple.screensharing.menuextra
  com.apple.SSInvitationAgent
  com.apple.sidecar-hid-relay
  com.apple.tipsd
  com.apple.videosubscriptionsd
  com.apple.watchlistd
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl bootout "user/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
  launchctl disable "user/$uid/$label"
done
for label in com.apple.screensharing com.apple.familycontrols com.apple.ftp-proxy; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
uid=$(id -u)
# enable same labels on gui/$uid, user/$uid, and system trio
# then: sudo shutdown -r now
```

## Test Result

**Date:** 2026-07-20 · target `codex` uid 502 · macOS 26.5.1

1. Pre: only `followupd` running among batch; rest idle-enabled.
2. Bootout all — clean; health PASS; log watch quiet.
3. Disable gui+user+system extras — confirmed.
4. Reboot — SSH OK; health PASS; process_count ~215–216; mem free 95%.
5. All 22 gui labels still disabled; junk procs none.
6. Log watch (followupd/tipsd/newsd/watchlistd/screensharing/intelligenceflowd/mapspush) — **0 hits**, no retry storm.

**Verdict: validated batch disable — keep disabled.**

## Expected Breakage

- Tips, News, TV watchlist / video subscriptions agents
- Maps push/sync/destination helpers
- My Photo Stream (`mstreamd`)
- Screen Sharing (agent + system daemon) / SS invitation
- Sidecar HID relay
- Follow Up notifications
- ClassKit progress (`progressd`)
- Family Controls useragent + system familycontrols
- ftp-proxy
- Extra Apple Intelligence context/flow daemons (if any residual)
- iCloud user notifications agent, cloudpaird, iMessage auto history deletion agent
- Motion tracking a11y agent, naturallanguaged

## Should still work

- SSH, network, GUI shell, coding
- Screenshots (`replayd`)
- universalaccessd (not touched)
- QuickLook (not touched this wave)

## Notes

- Tweaker: expose as one “consumer leftovers / gist idle agents” group, not 22 toggles.
- Profile: `conservative` / `coding`.
- Companion still-open gist items: QuickLook trio, BiomeAgent+biomed, cloudkeychainproxy3, protectedcloudstorage.
