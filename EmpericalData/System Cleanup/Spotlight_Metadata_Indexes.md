# Spotlight Metadata & Search Indexes

## Target Directories

- `/.Spotlight-V100` (root level of every mounted APFS volume)
- `~/Library/Metadata/CoreSpotlight`
- `/System/Volumes/Data/.Spotlight-V100`
- `/private/var/db/Spotlight-V100`

## Footprint

- **Typical Size:** `300 MB – 5.0+ GB`
- **Observed on Physical Mac:** `363 MB` (`~/Library/Metadata`)

## What Is Stored Here

- Full-text inverted search index databases (`store.db`, `.indexGroups`).
- Per-application CoreSpotlight record caches and tokenized keywords.

## Related Daemons & Agents

- `com.apple.metadata.mds`
- `com.apple.metadata.mds.index`
- `com.apple.metadata.mds.spindump`
- `com.apple.corespotlightd`

## Safety & Verdict

- **Safety Level:** **Safe to Delete (Purge / Rebuild)**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - If Spotlight services are **disabled** in Tweaker: Free up disk space permanently. Search daemons will not wake up to recreate the databases.
  - If Spotlight services are **enabled**: Deleting and triggering `mdutil -E /` forces a clean re-index, which resolves corrupted index issues and index bloat.
