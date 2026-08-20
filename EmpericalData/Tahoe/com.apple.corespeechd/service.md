# Local Speech Recognition / CoreSpeech

## Basics

- **Main labels:** `com.apple.corespeechd`, `com.apple.corespeechd_system`
- **Related labels:** `com.apple.DictationIM`, `com.apple.assistantd`, `com.apple.assistant_service`, `com.apple.assistant_cdmd`
- **XPC service:** `com.apple.speech.localspeechrecognition`
- **Processes:** `localspeechrecognition`, `corespeechd`, `corespeechd_system`, `assistantd`, `DictationIM`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `speech_siri_dictation`
- **Risk:** `2`
- **Verdict:** `disable for coding profile`

## What It Does

Local speech recognition, CoreSpeech, dictation input, Siri/assistant speech pipeline, voice trigger endpoints, and speech profile services.

Not needed for this coding-only machine because speech recognition is handled by external apps/services.

## Current Cost

Observed on 2026-06-19 under `codexadmin`:

```text
assistantd                44.8 MB
localspeechrecognition    36.8 MB
corespeechd               33.8 MB
localspeechrecognition    14.6 MB
voicebankingd             14.4 MB
corespeechd_system         4.3 MB
```

Speech asset payload:

```text
/System/Library/AssetsV2/com_apple_MobileAsset_UAF_Speech_AutomaticSpeechRecognition  395 MB
/System/Library/AssetsV2/com_apple_MobileAsset_UAF_Siri_UnderstandingASRHammer          27 MB
```

## Known Launchd Labels

Core local speech:

```text
gui/<uid>/com.apple.corespeechd
system/com.apple.corespeechd_system
gui/<uid>/com.apple.DictationIM
```

Assistant/Siri speech-adjacent:

```text
gui/<uid>/com.apple.assistantd
gui/<uid>/com.apple.assistant_service
gui/<uid>/com.apple.assistant_cdmd
gui/<uid>/com.apple.SiriTTSTrainingAgent
gui/<uid>/com.apple.voicebankingd
gui/<uid>/com.apple.voicememod
gui/<uid>/com.apple.speech.speechdatainstallerd
gui/<uid>/com.apple.speech.speechsynthesisd.arm64
gui/<uid>/com.apple.speech.speechsynthesisd.x86_64
gui/<uid>/com.apple.speech.synthesisserver
system/com.apple.asr
```

Call/telephony bridge that can own `localspeechrecognition`:

```text
gui/<uid>/com.apple.telephonyutilities.callservicesd
```

Already disabled earlier:

```text
gui/<uid>/com.apple.Siri.agent
gui/<uid>/com.apple.siriactionsd
gui/<uid>/com.apple.siriinferenced
gui/<uid>/com.apple.siriknowledged
gui/<uid>/com.apple.sirittsd
```

## Candidate Disable

Core local speech only:

```bash
uid=$(id -u)

for svc in \
com.apple.corespeechd \
com.apple.DictationIM
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

sudo launchctl disable system/com.apple.corespeechd_system
sudo launchctl bootout system/com.apple.corespeechd_system 2>/dev/null || true
```

Aggressive speech/assistant adjacent:

```bash
uid=$(id -u)

for svc in \
com.apple.assistantd \
com.apple.assistant_service \
com.apple.assistant_cdmd \
com.apple.SiriTTSTrainingAgent \
com.apple.voicebankingd \
com.apple.voicememod \
com.apple.speech.speechdatainstallerd \
com.apple.speech.speechsynthesisd.arm64 \
com.apple.speech.speechsynthesisd.x86_64 \
com.apple.speech.synthesisserver
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

sudo launchctl disable system/com.apple.asr
sudo launchctl bootout system/com.apple.asr 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.corespeechd \
com.apple.DictationIM \
com.apple.assistantd \
com.apple.assistant_service \
com.apple.assistant_cdmd \
com.apple.SiriTTSTrainingAgent \
com.apple.voicebankingd \
com.apple.voicememod \
com.apple.speech.speechdatainstallerd \
com.apple.speech.speechsynthesisd.arm64 \
com.apple.speech.speechsynthesisd.x86_64 \
com.apple.speech.synthesisserver
do
  launchctl enable gui/$uid/$svc
done

for svc in \
com.apple.corespeechd_system \
com.apple.asr
do
  sudo launchctl enable system/$svc
done
```

Reboot after rollback.

## Test Result

2026-06-19 staged temporary bootout test.

Stage 1, core local speech:

```text
Before:
localspeechrecognition  36.8 MB
corespeechd             33.8 MB
localspeechrecognition  14.6 MB
corespeechd_system       4.2 MB
total                   89.5 MB

Bootout:
com.apple.corespeechd
com.apple.DictationIM
system/com.apple.corespeechd_system

After:
localspeechrecognition  14.6 MB
total                   14.6 MB
```

Stage 2, assistant bridge:

```text
Before:
assistantd              44.7 MB
SAExtensionOrchestrator 17.9 MB
localspeechrecognition  14.6 MB
voicebankingd           14.4 MB
assistant_cdmd          11.0 MB
total                  102.6 MB

Bootout:
com.apple.assistantd
com.apple.assistant_service
com.apple.assistant_cdmd

After:
localspeechrecognition  14.6 MB
voicebankingd           14.4 MB
total                   29.0 MB
```

Stage 3, speech/TTS/voice:

```text
Before:
localspeechrecognition  14.6 MB
voicebankingd           14.4 MB
total                   29.0 MB

Bootout:
com.apple.SiriTTSTrainingAgent
com.apple.voicebankingd
com.apple.voicememod
com.apple.speech.speechdatainstallerd
com.apple.speech.speechsynthesisd.arm64
com.apple.speech.speechsynthesisd.x86_64
com.apple.speech.synthesisserver
system/com.apple.asr

After:
localspeechrecognition  14.6 MB
total                   14.6 MB
```

The last `localspeechrecognition` was owned by `callservicesd`:

```text
responsible path = /System/Library/PrivateFrameworks/TelephonyUtilities.framework/callservicesd
domain = pid/395 [callservicesd]
XPC_SERVICE_NAME = com.apple.speech.localspeechrecognition
```

Stage 4, telephony/calls bridge:

```text
Before:
callservicesd                      39.5 MB
FaceTime FTConversationService     11.6 MB
total                              51.0 MB

Bootout:
com.apple.telephonyutilities.callservicesd

After:
total                               0.0 MB
```

Final broad filter after all temporary bootouts:

```text
TOTAL_SPEECH_RELATED_RSS: 0 processes, 0.0 MB
```

Temporary only. Persistent `launchctl disable` and reboot test not applied yet.

2026-06-19 persistent disable reboot test succeeded.

Persistent disable applied:

```bash
uid=$(id -u)

for svc in \
com.apple.corespeechd \
com.apple.DictationIM \
com.apple.assistantd \
com.apple.assistant_service \
com.apple.assistant_cdmd \
com.apple.SiriTTSTrainingAgent \
com.apple.voicebankingd \
com.apple.voicememod \
com.apple.speech.speechdatainstallerd \
com.apple.speech.speechsynthesisd.arm64 \
com.apple.speech.speechsynthesisd.x86_64 \
com.apple.speech.synthesisserver \
com.apple.telephonyutilities.callservicesd
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

for svc in \
com.apple.corespeechd_system \
com.apple.asr
do
  sudo launchctl disable system/$svc
  sudo launchctl bootout system/$svc 2>/dev/null || true
done
```

After reboot at 25 seconds uptime:

```text
SPEECH_RELATED_RSS: 0 processes, 0.0 MB

com.apple.assistant_service => disabled
com.apple.voicebankingd => disabled
com.apple.speech.speechsynthesisd.x86_64 => disabled
com.apple.SiriTTSTrainingAgent => disabled
com.apple.speech.speechdatainstallerd => disabled
com.apple.speech.synthesisserver => disabled
com.apple.telephonyutilities.callservicesd => disabled
com.apple.assistant_cdmd => disabled
com.apple.DictationIM => disabled
com.apple.assistantd => disabled
com.apple.voicememod => disabled
com.apple.corespeechd => disabled
com.apple.speech.speechsynthesisd.arm64 => disabled
com.apple.asr => disabled
com.apple.corespeechd_system => disabled
```

Console login and passwordless sudo still worked.
