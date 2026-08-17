# MediaExperience audio routing — `audiomxd` (audiomxd-off — DO NOT DISABLE)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | `com.apple.audiomxd` only                                     |
| Category      | `ui_required` — audio sessions / routing / system sounds      |
| Risk Level    | **4** — disable kills all sound immediately (GUI-confirmed)   |
| Profile       | **protected — keep enabled**                                  |

**GUI-confirmed:** all sound disappears immediately after bootout/disable.

## What It Does (за что отвечает)

System **MediaExperience** daemon — per-user audio session layer moved to `audiomxd` on modern macOS (`MoveMXRoutingToAudiomxdOnMac`).

| Responsibility | Detail |
|----------------|--------|
| Audio sessions | `com.apple.audio.AudioSession` |
| Routing | `routingcontext`, `routediscoverer`, `mediaexperience.endpoint` |
| Volume | `coremedia.volumecontroller` |
| System sounds (partial) | `com.apple.audio.SystemSoundServer-OSX` |
| AirPlay agent | `com.apple.airplay.agent.services` |
| Voice trigger | `com.apple.audio.voicetrigger.xpc` |
| BT accessory bridge | `MXAudioAccessoryServices` ↔ `audioaccessoryd` |

**Not the HAL:** `coreaudiod` stays separate. Both are needed for working audio.

| Label | Domain | Process | Plist |
|-------|--------|---------|-------|
| `com.apple.audiomxd` | system | `audiomxd` | `/System/Library/LaunchDaemons/com.apple.audiomxd.plist` |

**Binary:** `/usr/libexec/audiomxd` (user `_audiomxd`)

**Launch:** no `KeepAlive`; on-demand via Mach IPC (`kickstart` / client connect). `EnablePressuredExit=false`.

## CPU loop note (separate issue)

When `com.apple.BTServer.cloudpairing` / `audioaccessoryd` is **disabled**, `audiomxd` can spin ~70%+ CPU in retry loop:

```text
MXAudioAccessoryServices handleServerDeath
  → initializeAudioAccessoryConnection
    → BTAudioRoutingRequest _ensureXPCStarted
      → xpc_connection_bootstrap_look_up_slow (dead service)
```

Collateral: `launchd` ~30%, `configd` ~19%.

**Fix for CPU burn:** re-enable `BTServer.cloudpairing`, **not** disable `audiomxd`. **Applied 2026-06-27** — `audioaccessoryd` restored; `audiomxd`/`launchd`/`configd` returned to 0% CPU.

## Observed Cost

| State | RSS | CPU |
|-------|-----|-----|
| Idle (accessory daemon present) | ~17 MB | 0% |
| Loop (`audioaccessoryd` off) | ~19 MB | ~70–84% |
| Disabled | 0 | n/a |

## Disable (system — do not use)

```bash
sudo launchctl bootout system/com.apple.audiomxd 2>/dev/null || true
sudo launchctl disable system/com.apple.audiomxd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.audiomxd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.audiomxd.plist
sudo launchctl kickstart system/com.apple.audiomxd
```

## Test Result

**Date:** 2026-06-27 — experiment **audiomxd-off** (two attempts)

### Attempt 1 (headless)

1. Bootout/disable `system/com.apple.audiomxd` — gone immediately.
2. **CPU relief confirmed:** `audiomxd` gone; `launchd` 30%→0%; `configd` 19%→0%; no respawn 30s.
3. `coreaudiod`, `replayd` still running quiet.
4. Rolled back via `kickstart` — process returned.

### Attempt 2 (GUI user observation)

1. Bootout/disable again.
2. **GUI-confirmed: all sound disappears immediately.**
3. User verdict: **cannot disable.**

### Restore after final test

```bash
sudo launchctl enable system/com.apple.audiomxd
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.audiomxd.plist
sudo launchctl kickstart system/com.apple.audiomxd
```

`audiomxd` running again (pid 2126).

**Verdict: protected — keep enabled. Do not include in No Audio / Reduced Audio profiles.**

## Exact Breakage Notes (GUI-confirmed)

| Broken | Detail |
|--------|--------|
| All system audio output | **Immediate** — user confirmed sound fully gone |
| Audio sessions / routing | MediaExperience endpoints unavailable |
| System sounds / volume UX | `SystemSoundServer-OSX` path down |
| AirPlay agent layer | Mach services inactive |

**Does NOT break (headless attempt 1):** SSH; Wi-Fi; `coreaudiod` process; `replayd`; boot.

## Neighbors

| Component | Notes |
|-----------|-------|
| `coreaudiod` | keep running — HAL; not a substitute for `audiomxd` |
| `systemsoundserverd` | parallel/related; references `audiomxd` |
| `intelligentroutingd` | smart routing neighbor |
| `mediaremoted` | references `audiomxd` |
| `replayd` | references `audiomxd` — protected anyway |
| `audioaccessoryd` | when off → `audiomxd` CPU loop; re-enable to fix CPU, not disable `audiomxd` |

## Protected list entry

Add to tweaker **protected** profile:

```text
com.apple.audiomxd  # all sound dies immediately (GUI-confirmed)
com.apple.replayd   # screenshots (existing)
```