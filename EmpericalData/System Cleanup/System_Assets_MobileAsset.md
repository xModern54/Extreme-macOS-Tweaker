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

## Empirical Test Results (Tested on Physical Mac)

- **Spotlight & Suggestions Test (Deleted ~185 MB):**
  - `com_apple_MobileAsset_UAF_SearchQueryUnderstanding` (106 MB)
  - `com_apple_MobileAsset_UAF_SearchQueryUnderstandingOverrides` (1.4 MB)
  - `com_apple_MobileAsset_CoreSuggestions` (77 MB)
  - `com_apple_MobileAsset_CoreSuggestionsModels` (280 KB)
  - `com_apple_MobileAsset_SpotlightResources` (256 KB)
  - *Result:* All 5 paths remained completely absent after reboot and 60s uptime.

- **Siri Voice Trigger & Speech Models Test (Deleted ~193 MB):**
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_VoiceTriggerAssetsASMac` (94 MB)
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_VoiceTriggerAssets` (50 MB)
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_VoiceTriggerAssetsStudioDisplay` (43 MB)
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_SpeakerRecognitionASMacAssets` (4.1 MB)
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_SpeechEndpointMacOSAssets` (1.4 MB)
  - `PreinstalledAssetsV2/RequiredByOs/com_apple_MobileAsset_VoiceTriggerAssetsMac` (560 KB)
  - `AssetsV2/com_apple_MobileAsset_VoiceTriggerAssetsStudioDisplay` (80 KB)
  - *Result:* `PreinstalledAssetsV2` dropped from 195 MB to 1.6 MB. Zero items recreated after reboot and 60s uptime.

- **AI, Photos, Shortcuts & Linguistic Data Test (Deleted ~1.05 GB):**
  - `com_apple_MobileAsset_UAF_Photos_SpatialPhotosRelive` (417 MB)
  - `com_apple_MobileAsset_UAF_LinguisticData` (389 MB)
  - `com_apple_MobileAsset_DictionaryServices_dictionary3macOS` (124 MB)
  - `com_apple_MobileAsset_UAF_Shortcuts_Generator` (86 MB)
  - `com_apple_MobileAsset_UAF_Translation_Assets` (33 MB)
  - *Result:* `AssetsV2` shrunk from 1.4 GB to just **27 MB** total. All paths remained absent (`[CLEAN]`). Keyboard layout switching and baseline typing remain 100% functional.



