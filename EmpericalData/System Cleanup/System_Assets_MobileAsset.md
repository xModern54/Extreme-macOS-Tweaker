# System Assets & MobileAsset Repositories (AssetsV2)

## Target Directories

- `/System/Volumes/Data/System/Library/AssetsV2`
- `/System/Volumes/Data/System/Library/PreinstalledAssetsV2`
- `/System/Volumes/Data/System/Library/Assets`
- `/System/Volumes/Data/System/Library/PreinstalledAssets`

## Footprint

- **Typical Size:** `1.4 GB – 4.5+ GB`
- **Observed on Physical Mac:** `1.4 GB` (`/System/Volumes/Data/System/Library/AssetsV2`)

## What Is Stored Here

- Over-the-air downloadable components managed by `mobileassetd`:
  - Siri neural text-to-speech (TTS) voice models (`com.apple.MobileAsset.VoiceServicesVocalizerVoice`).
  - Offline dictation and speech recognition packages (`com.apple.MobileAsset.SpeechRecognition`).
  - CoreML natural language models and autocorrect lexicons.
  - On-demand system fonts and language-specific transliteration models.
  - Vision / Image playground preview weights and CoreImage neural filters.

## Related Daemons & Agents

- `com.apple.mobileassetd`
- `com.apple.corespeechd`
- `com.apple.siriappintentsd`
- `com.apple.translationd`

## Safety & Verdict

- **Safety Level:** **Safe to Delete**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - If Siri, Speech, and Translation services are **disabled** in Tweaker: These models are unused dead weight. They will **not** be redownloaded.
  - If services are **enabled**: `mobileassetd` will download only the active language/voice when explicitly selected in System Settings.
  - Standard system operation, keyboard typing, and default fonts remain fully functional (default fonts and system voices are embedded inside the sealed read-only System root volume).
