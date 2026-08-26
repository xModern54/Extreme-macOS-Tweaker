# User & System Caches & Darwin Temp Folders

## Target Directories

- `~/Library/Caches/*`
- `/Library/Caches/*`
- `/private/var/folders/*/*/*/com.apple.*`
- `/private/var/folders/*/*/*/C/` (DARWIN_USER_CACHE)
- `/private/var/folders/*/*/*/T/` (DARWIN_USER_TEMP)

## Footprint

- **Typical Size:** `1.0 GB – 10.0+ GB`
- **Observed on Physical Mac:**
  - `~/Library/Caches`: `559 MB` (Google Chrome: 415 MB, GeoServices: 55 MB, helpd: 32 MB, VisualIntelligence: 18 MB)
  - `/private/var/folders`: `142 MB`

## What Is Stored Here

- HTTP network caches, web asset previews, DNS query caches, QuickLook thumbnail caches, and font glyph rasterizations.
- Temporary build objects, compiler pipes, and intermediate IPC files in `var/folders`.

## Safety & Verdict

- **Safety Level:** **100% Safe to Delete**
- **Verdict:** `purge`
- **Best Practice for Cleanup:**
  - Wipe contents of `~/Library/Caches/*` and `/Library/Caches/*`.
  - For `/private/var/folders`, it is safest to purge items older than 24–48 hours or clean during a reboot cycle so running processes don't hold active open file descriptors.

## Empirical Test Results (Tested on Physical Mac)

- **Target:** `/Library/Caches/com.apple.aned` (~379 MB deleted)
- **What was cleared:** Precompiled neural graph weights in `ModelAssetsCache` (276 MB) and platform caches for `mediaanalysisd`, `replayd`, `campo`, `Safari`, `visualintelligenced` in `tmp/` (102 MB).
- **Post-Reboot Behavior (60s observation):**
  - Directory size: **0 B** (empty directory tree).
  - CPU usage: **92.8% idle**, **0.0% user CPU**.
  - No aggressive background compilation or Metal/NPU compiler storms were triggered upon reboot. `aned` remained sleeping in low-overhead state.
- **Verdict:** **100% Safe to purge**.

- **Target:** `/Library/Caches/com.apple.iconservices.store` (~908 MB deleted)
- **What was cleared:** 1,654 cached `.isdata` icon files accumulated from past application launches and document previews.
- **Post-Reboot Behavior (60s observation):**
  - Directory size: Rebuilt only **1.6 MB** (11 active system icon bitmaps).
  - Net permanent storage gain: **~906 MB**.
  - System Finder and Dock loaded icons seamlessly with zero visual artifacts.
- **Verdict:** **100% Safe to purge**.


