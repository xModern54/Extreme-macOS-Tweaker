# Game Stack — Controller / Game Center / Sports (remainder)

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | Remaining game stack after Game Policy disable                 |
| Category      | `consumer` / gaming                                            |
| Risk Level    | 1–2 for coding target without gamepads or Game Center          |

## What It Does

| Label | Process | Role |
|-------|---------|------|
| `com.apple.GameController.gamecontrollerd` | `gamecontrollerd` | System gamepad/USB/BT controller daemon (`_gamecontrollerd`) |
| `com.apple.GameController.gamecontrolleragentd` | `gamecontrolleragentd` | Per-user Game Controller agent |
| `com.apple.gamed` | `gamed` | Game Center daemon, APS, social gaming |
| `com.apple.gamesaved` | `gamesaved` | Game save sync helper |
| `com.apple.GameOverlayUI` | `GameOverlayUI` | Game Center overlay UI (LaunchAngels) |
| `com.apple.sportsd` | `sportsd` | Apple Sports sessions / APS |

**Already disabled earlier (same stack, separate test):**

| Label | Process |
|-------|---------|
| `com.apple.GamePolicyAgent` | `GamePolicyAgent` |
| `com.apple.gamepolicyd` | `gamepolicyd` |

See `services/com.apple.GamePolicyAgent/service.md`.

## Observed Cost (before disable)

| Process | State | RSS |
|---------|-------|-----|
| `gamecontrollerd` | running | ~13 MB |
| `gamecontrolleragentd` | running | ~11 MB |
| `gamed`, `gamesaved`, `GameOverlayUI`, `sportsd` | idle | 0 |
| **This wave** | | **~24 MB** |
| Game Policy (prior) | was running | ~50 MB |

## Launchd Labels

Six labels disabled in this test (1 system + 5 gui). Plists under `/System/Library/LaunchAgents/`, `/System/Library/LaunchDaemons/`, and `LaunchAngels/` for GameOverlayUI.

## Disable

```bash
uid=$(id -u)
sudo launchctl bootout system/com.apple.GameController.gamecontrollerd 2>/dev/null || true
sudo launchctl disable system/com.apple.GameController.gamecontrollerd
for label in com.apple.GameController.gamecontrolleragentd com.apple.gamed com.apple.gamesaved com.apple.GameOverlayUI com.apple.sportsd; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
sudo launchctl enable system/com.apple.GameController.gamecontrollerd
for label in com.apple.GameController.gamecontrolleragentd com.apple.gamed com.apple.gamesaved com.apple.GameOverlayUI com.apple.sportsd; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `gamecontrollerd` + `gamecontrolleragentd` running (~24 MB); four idle labels enabled.
2. Bootout/disable all six — processes gone immediately.
3. `GamePolicyAgent` / `gamepolicyd` disable flags unchanged.
4. 30-second delayed check — no game stack processes returned.
5. Reboot — SSH back ~21 seconds.
6. Post-reboot: no `gamecontrollerd`, `gamecontrolleragentd`, `gamed`, `gamesaved`, `sportsd`, or GameOverlayUI processes.
7. All eight game-related labels disabled (6 + 2 prior Game Policy).
8. **SSH:** OK.
9. **Bluetooth:** State On, `bluetoothd` running.
10. **HID:** internal keyboard/trackpad present in IOHID; `AppleUserHIDDrivers` loaded — keyboard/mouse/trackpad path alive.
11. **Log storm:** 0 boot-time lines for GameController/gamecenter/gamed/gamesaved/sportsd; no error/retry loops in 5m window.
12. 45-second delayed check — still clean.
13. Process count: ~326.

**Verdict: full game stack disabled safely on coding experimental target.**

## Expected Breakage

- USB/Bluetooth game controllers on Mac.
- Game Center, game saves sync, Game Overlay UI, Apple Sports.
- Game policy (already disabled separately).

**Not broken (verified):** SSH, Wi-Fi, Bluetooth power, built-in keyboard/trackpad/mouse HID.

## Notes

- Completes game stack removal together with `GamePolicyAgent` / `gamepolicyd`.
- `controlcenter` still listens for `GameController.events.controllers-changed` but controller daemon is gone.
- Re-enable GameController labels if using gamepads on this Mac.