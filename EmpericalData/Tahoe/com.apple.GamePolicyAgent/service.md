# Game Policy — Parental Controls / Game Restrictions

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Game Policy (`GamePolicyAgent` + `gamepolicyd`)                 |
| Category      | `ui_required` / consumer parental controls                     |
| Risk Level    | 1 — not needed for coding workflow; not boot-critical          |

## What It Does

Apple Game Policy infrastructure for game-related restrictions, policies, and mobile-asset policy database updates:

- **GamePolicyAgent** (per-user) — user-facing game policy agent and notification delegate
- **gamepolicyd** (system) — privileged game policy daemon, mobile asset DB maintenance

Used for Screen Time / game restriction features and game policy enforcement. Not required for software development, SSH, or general desktop use on an experimental coding target.

## Observed Cost (before disable)

| Process           | Domain | RSS     |
|-------------------|--------|---------|
| `GamePolicyAgent` | gui    | ~31 MB  |
| `gamepolicyd`     | system | ~19 MB  |
| **Total**         |        | **~50 MB** |

## Launchd Labels

| Label                       | Plist                                                          | Domain |
|-----------------------------|----------------------------------------------------------------|--------|
| `com.apple.GamePolicyAgent` | `/System/Library/LaunchAgents/com.apple.GamePolicyAgent.plist` | gui    |
| `com.apple.gamepolicyd`     | `/System/Library/LaunchDaemons/com.apple.gamepolicyd.plist`    | system |

### Endpoints

**GamePolicyAgent:**
```text
com.apple.GamePolicyAgent.daemon
com.apple.usernotifications.delegate.com.apple.GamePolicyNotifications
```

**gamepolicyd:**
```text
com.apple.gamepolicyd.app
com.apple.gamepolicyd.app.privileged
com.apple.gamepolicyd.mobile-asset
com.apple.gamepolicyd.tool
com.apple.gamepolicyd.tool.privileged
```

### LaunchEvents

```text
GamePolicyAgent: com.apple.gamepolicy.agent.launch (notifyd)
gamepolicyd:       com.apple.gamepolicy.daemon.launch (notifyd)
gamepolicyd:       com.apple.gamepolicy.mobileasset.DB.update (xpc.activity, ~5-day interval, network)
```

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.GamePolicyAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.GamePolicyAgent"
sudo launchctl bootout system/com.apple.gamepolicyd 2>/dev/null || true
sudo launchctl disable system/com.apple.gamepolicyd
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.GamePolicyAgent"
sudo launchctl enable system/com.apple.gamepolicyd
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `GamePolicyAgent` ~31 MB, `gamepolicyd` ~19 MB (both running).
2. Bootout gui `GamePolicyAgent` — agent disappeared immediately.
3. Bootout system `gamepolicyd` — daemon disappeared (brief lag on first check, confirmed gone on retry).
4. No errors in logs after bootout.
5. 30-second delayed check — neither process returned.
6. Disabled both labels — confirmed in `launchctl print-disabled`.
7. Rebooted target; SSH back in ~17 seconds.
8. Post-reboot health: SSH, login, gateway, DNS, memory pressure OK.
9. No Game Policy processes after reboot.
10. No gamepolicy-related error log entries during boot.
11. Process count: **338** (down from 342).

**Verdict: safe to disable on coding experimental target.** ~50 MB saved.

## Expected Breakage

- Game policy / Screen Time game restriction enforcement on this Mac.
- Game policy mobile-asset database updates.
- GamePolicy user notifications.

No observed impact on SSH, networking, coding tools, or boot stability.

## Notes

- Pair disable: agent without daemon (or vice versa) is incomplete; always disable both labels.
- Re-enable if using parental controls or game restrictions on this machine.
- **2026-06-20 follow-up:** remainder game stack disabled — GameController, `gamed`, `gamesaved`, `GameOverlayUI`, `sportsd`. See `services/com.apple.GameController.gamecontrollerd/service.md` (8 game labels total now disabled).