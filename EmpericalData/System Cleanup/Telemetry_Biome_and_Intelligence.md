# Telemetry, Biome, Duet & Trial Datastores

## Target Directories

- `~/Library/Biome`
- `~/Library/DuetExpertCenter`
- `~/Library/IntelligencePlatform`
- `~/Library/Trial`
- `/private/var/db/Biome`
- `/private/var/db/CoreDuet`

## Footprint

- **Typical Size:** `300 MB – 1.5+ GB`
- **Observed on Physical Mac:**
  - `~/Library/Biome`: `77 MB`
  - `~/Library/DuetExpertCenter`: `150 MB`
  - `~/Library/IntelligencePlatform`: `57 MB`
  - `~/Library/Trial`: `32 MB`
  - Total on test system: `~316 MB`

## What Is Stored Here

- **Biome:** High-frequency event streams recording every app launch, device orientation change, media playback, network transition, and UI interaction.
- **DuetExpertCenter / CoreDuet:** Routine prediction algorithms and proactive Siri shortcut models.
- **IntelligencePlatform:** Local knowledge graphs and semantic associations.
- **Trial:** Apple client-side A/B experimentation payloads and rollout treatments.

## Related Daemons & Agents

- `com.apple.biomesyncd`
- `com.apple.analyticsd`
- `com.apple.triald`
- `com.apple.intelligencetasksd`
- `com.apple.generativeexperiencesd`

## Safety & Verdict

- **Safety Level:** **100% Safe to Delete**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - If analytics, Biome, and predictive services are **disabled** in Tweaker: These stores remain empty and cease consuming CPU/disk I/O.
  - If services are enabled: New event streams start collecting from scratch with no loss of user data (only predictive history resets).

## Empirical Test Results (Tested on Physical Mac)

- **Target User Datastores Purged (~1.32 GB deleted):**
  - `~/Library/Containers/com.apple.mediaanalysisd` (410 MB -> **48 KB**; **~410 MB freed**)
  - `~/Library/Metadata/CoreSpotlight` (363 MB -> **0 B**; **363 MB freed**)
  - `~/Library/Group Containers/group.com.apple.SiriTTS` (261 MB -> **4 KB**; **~261 MB freed**)
  - `~/Library/DuetExpertCenter` (150 MB -> **0 B**; **150 MB freed**)
  - `~/Library/Biome` (77 MB -> **0 B**; **77 MB freed**)
  - `~/Library/IntelligencePlatform` (57 MB -> **0 B**; **57 MB freed**)
- **Post-Reboot & 60s Uptime Verification:**
  - `CoreSpotlight`, `DuetExpertCenter`, `Biome`, `IntelligencePlatform` remained **0 B**.
  - `mediaanalysisd` and `SiriTTS` recreated only 4–48 KB minimal container manifests.
  - Total permanent storage gain: **~1.32 GB**.

