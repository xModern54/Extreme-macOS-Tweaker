# AX Asset Loader / TTS voices — `com.apple.accessibility.axassetsd`

## Basics

| Field         | Value |
|---------------|-------|
| Feature group | Accessibility TTS assets + AudioUnit-Speech voice plugins |
| Main label    | `com.apple.accessibility.axassetsd` |
| Category      | accessibility_tts |
| Risk Level    | 2 — kills system text-to-speech voices; should not break boot |
| Verdict       | **keep disabled** on experimental coding target |

## What It Does

`axassetsd` is the **AXAssetLoader** user agent: accessibility asset manager, primarily for **text-to-speech voices**.

Concrete jobs:

- Owns XPC: `com.apple.accessibility.voices`, `.voices.admin`, `.axassetsd.service`
- Maintains `~/Library/Accessibility/voicedb.sqlite`
- Downloads/updates MobileAsset voice packs (Siri TTS, Vocalizer, Gryphon, custom/Personal Voice) and a few a11y ML packs (Image Caption, Magnifier, AX Icon Vision)
- **Hosts** ExtensionKit `com.apple.AudioUnit-Speech` plugins (AUSP) via runningboard — these have **no** own launchd plists

Child extensions observed under `domain = pid/<axassetsd>`:

| Process | Bundle / XPC |
|---------|----------------|
| `SiriAUSP` | `com.apple.texttospeech.SiriAUSP` |
| `MacinTalkAUSP` | `com.apple.speech.MacinTalkFramework.MacinTalkAUSP` |
| `MauiAUSP` | `com.apple.ax.MauiTTSSupport.MauiAUSP` |
| `KonaSynthesizer` | `com.apple.ax.KonaTTSSupport.KonaSynthesizer` |
| `WardaSynthesizer` | `com.apple.speech.MacinTalkFramework.WardaSynthesizer` |

Not the same as `universalaccessd` (session a11y — **do not disable** that one).

## Observed Cost (before disable)

| Process | RSS |
|---------|-----|
| `axassetsd` | ~30 MB |
| `SiriAUSP` | ~38 MB |
| `MacinTalkAUSP` | ~38 MB |
| `KonaSynthesizer` | ~39 MB |
| `WardaSynthesizer` | ~26 MB |
| `MauiAUSP` | ~14 MB |
| **Total** | **~185 MB** |

## Launchd Labels

| Label | Plist | Domain |
|-------|-------|--------|
| `com.apple.accessibility.axassetsd` | `/System/Library/LaunchAgents/com.apple.accessibility.axassetsd.plist` | gui |

AUSP children: **no launchd labels** — cannot `launchctl disable` them directly.

### Already disabled related (leave alone)

```text
corespeechd, corespeechd_system, sirittsd, SiriTTSTrainingAgent
speech.synthesisserver, speech.speechdatainstallerd
speechsynthesisd.arm64 / .x86_64
voicebankingd, voicememod, Siri.agent, assistantd, …
```

### Explicitly NOT disabled with this group

```text
universalaccessd          — DO NOT (settings persistence / a11y session)
AccessibilityUIServer     — UI a11y visuals
runningboardd             — core
AudioComponentRegistrar   — broader AU registry
coreaudiod                — system audio
```

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.accessibility.axassetsd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.accessibility.axassetsd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.accessibility.axassetsd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-07-20  
**Target:** `codex` uid 502, macOS 26.5.1  
**Health:** `scripts/health-check.sh` (incl. `--log-watch` storm/retry)

1. Pre-bootout health — PASS.
2. Bootout `com.apple.accessibility.axassetsd` — host + all 5 AUSP gone immediately (~185 MB).
3. Post-bootout health — PASS; processes gone; **log watch quiet** (0 hits / 60s, no retry).
4. Disable label — confirmed in `print-disabled`.
5. Reboot — SSH ~15 s.
6. Post-reboot health — PASS; still disabled; processes still gone; **log watch quiet** (0 hits / 120s).
7. Delayed +40 s — still clean; no return; no log storm.
8. process_count ~217–229; memory free ~94–95%; WindowServer + replayd + universalaccessd OK.

**Verdict: validated disable — keep disabled.** Expected TTS breakage only; no retry loops.

## Expected Breakage

- System TTS voices (`say`, Speak Selection, Speak Screen)
- VoiceOver speech output (voices unavailable)
- Live Speech / Personal Voice asset path
- Download/update of accessibility voice and related a11y model assets

## Should still work

- SSH, network, GUI shell, screenshots (`replayd`)
- `universalaccessd` session features (contrast etc.) — still running
- Normal app audio (`coreaudiod`)
- Coding workflow

## Notes

- Tweaker UI: *Do you need macOS text-to-speech / VoiceOver voices on this Mac?*
- Profile: `coding` / `aggressive`
- Regression:

```bash
./scripts/health-check.sh --host c --phase check \
  --gone 'axassets|SiriAUSP|MacinTalkAUSP|MauiAUSP|KonaSynthes|WardaSynthes' \
  --disabled-gui com.apple.accessibility.axassetsd \
  --log-watch axassetsd \
  --log-watch SiriAUSP \
  --log-window 90 --log-max 30
```
