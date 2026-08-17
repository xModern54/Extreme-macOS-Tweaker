# Call Services / AVConference — FaceTime & CallKit stack

## Basics

| Field         | Value |
|---------------|-------|
| Feature group | FaceTime / CallKit / Phone Continuity call orchestration |
| Main label    | `com.apple.telephonyutilities.callservicesd` |
| Category      | messages_imessage_ids / consumer telephony |
| Risk Level    | 2 — disables Apple call features; should not break boot |
| Verdict       | **keep disabled** on experimental coding target |

## What It Does

Apple's user-session call stack after the lower IDS/iMessage layer:

| Process | Role |
|---------|------|
| `callservicesd` | CallKit host, VoIP push endpoints, call state, conversation manager, FaceTime alloy IDS-wake ports, Group Activities / SharePlay hosts, FaceTime notification delegate |
| `FTConversationService` | XPC child of callservicesd — FaceTime conversation links |
| `avconferenced` | AVConference media path (`com.apple.videoconference.camera`) — camera/audio session plumbing for Apple video calls |
| `callintelligenced` | Call intelligence helper (demand; was idle) |

This sits **above** the already-disabled Messages/IDS layer (`imagent`, `identityservicesd`, `facetimemessagestored`, `callhistoryd`, `CommCenter`).

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `callservicesd` | ~39 MB |
| `FTConversationService` | ~11 MB |
| `avconferenced` | ~20 MB |
| **Total** | **~70 MB** |

CPU idle. Started at login via mach IPC (`immediate reason = ipc`).

## Launchd Labels

| Label | Plist | Domain | Binary |
|-------|-------|--------|--------|
| `com.apple.telephonyutilities.callservicesd` | `/System/Library/LaunchAgents/com.apple.telephonyutilities.callservicesd.plist` | gui | `TelephonyUtilities.framework/callservicesd` |
| `com.apple.videoconference.camera` | `/System/Library/LaunchAgents/com.apple.avconferenced.plist` | gui | `/usr/libexec/avconferenced` |
| `com.apple.callintelligenced` | `/System/Library/LaunchAgents/com.apple.callintelligenced.plist` | gui | demand / idle |

### Important Mach / XPC endpoints

**callservicesd:**

```text
com.apple.callkit.service
com.apple.callkit.callcontrollerhost
com.apple.callkit.callsourcehost
com.apple.callkit.networkextension.voip
com.apple.telephonyutilities.callservicesdaemon.voip
com.apple.telephonyutilities.callservicesdaemon.callstatecontroller
com.apple.telephonyutilities.callservicesdaemon.conversationmanager
com.apple.private.alloy.facetime.{audio,video,multi,sync}-idswake
com.apple.private.alloy.phonecontinuity*-idswake
com.apple.group-activities.conversationmanagerhost
com.apple.copresence.conversationmanagerhost
com.apple.usernotifications.delegate.com.apple.facetime
```

**avconferenced:**

```text
com.apple.videoconference.camera
com.apple.videoconference.avconference
com.apple.videoconference.speechtranslation
```

### Already disabled prerequisites (do not re-enable for this tweak)

```text
com.apple.imagent
com.apple.identityservicesd
com.apple.facetimemessagestored
com.apple.callhistoryd
com.apple.CallHistorySyncHelper
com.apple.CallHistoryPluginHelper
com.apple.CommCenter
com.apple.linkd
cmio.* / cameracaptured / ContinuityCapture (separate camera wave)
```

### Explicitly NOT in this group

```text
mediaremoteagent / mediaremoted   — Now Playing; separate feature
replayd                           — screenshots; PROTECTED
coreaudiod                        — system audio
WindowServer / loginwindow        — GUI core
```

## Disable

```bash
uid=$(id -u)
labels=(
  com.apple.telephonyutilities.callservicesd
  com.apple.videoconference.camera
  com.apple.callintelligenced
)
for label in "${labels[@]}"; do
  launchctl bootout "gui/$uid/$label" 2>/dev/null || true
  launchctl disable "gui/$uid/$label"
done
```

## Rollback

```bash
uid=$(id -u)
for label in \
  com.apple.telephonyutilities.callservicesd \
  com.apple.videoconference.camera \
  com.apple.callintelligenced; do
  launchctl enable "gui/$uid/$label"
done
sudo shutdown -r now
```

## Test Result

**Date:** 2026-07-20  
**Target:** `codex` uid 502, macOS 26.5.1  
**Health script:** `scripts/health-check.sh`

1. **Pre-bootout health** — PASS (SSH, route, DNS, core procs, WindowServer, replayd, memory 95%).
2. **Bootout** 3 gui labels — `callservicesd`, `FTConversationService`, `avconferenced` gone immediately.
3. **Post-bootout health** — PASS; `--gone` clean; process_count 235 → 226.
4. **Delayed 20 s** — still none; no retry loop in logs.
5. **Disable** all 3 labels — confirmed in `launchctl print-disabled gui/502`.
6. **Reboot** — SSH back ~18 s.
7. **Post-reboot health** — PASS; all 3 still disabled; no target processes; memory 94%; WindowServer + replayd OK.
8. **Feature probe:** `open -a FaceTime` — FaceTime.app GUI process started (~106 MB) but **did not** spawn `callservicesd` / `avconferenced` / `FTConversationService`. Backend stack stays dead.
9. FaceTime app killed after probe; machine left clean.

**Verdict: validated disable for no-FaceTime / no-Phone-Continuity coding target — keep disabled.** ~70 MB saved at idle.

## Expected Breakage

- FaceTime audio/video calls (app may open as empty shell).
- Answer/place iPhone calls on this Mac (Phone Continuity).
- SharePlay / Group Activities conversation hosting.
- CallKit VoIP for apps that use Apple CallKit (not typical Zoom/Teams/Discord stacks).
- FaceTime notification delegate / call UI plumbing.
- Local Call History UI that depends on callservicesd.

## Should still work

- SSH, Wi-Fi, DNS, default route.
- Zoom / Teams / browser WebRTC (own stacks).
- System audio (`coreaudiod`), screenshots (`replayd`).
- Coding toolchain (git may be absent on bare target — unrelated).

## Notes

- Future tweaker UI question: *Do you use FaceTime / iPhone calls on this Mac / CallKit VoIP?*
- Profile: `coding` / `aggressive`.
- Pair with existing Messages/IDS disable for a complete Apple communication cut.
- Standard regression command after any later change:

```bash
./scripts/health-check.sh --host c --phase manual \
  --gone 'callservice|avconference|FTConversation|callintelligence' \
  --disabled-gui com.apple.telephonyutilities.callservicesd \
  --disabled-gui com.apple.videoconference.camera \
  --disabled-gui com.apple.callintelligenced
```
