# Aerial Video Wallpapers & Screen Savers

## Target Directories

- `~/Library/Application Support/com.apple.wallpaper`
- `/Library/Application Support/com.apple.idleassetsd`
- `/private/var/folders/*/*/*/com.apple.wallpaper.agent`

## Footprint

- **Typical Size:** `450 MB – 15.0+ GB` (each 4K/HDR Aerial clip is ~400–900 MB)
- **Observed on Physical Mac:** `451 MB` (`~/Library/Application Support/com.apple.wallpaper/Store`)

## What Is Stored Here

- 4K ProRes/HEVC slow-motion aerial drone videos downloaded from Apple CDN for Sonoma, Sequoia, and Tahoe screensavers/wallpapers.
- Cached thumbnails and preview playlists for dynamic wallpaper collections.

## Related Daemons & Agents

- `com.apple.wallpaper.agent`
- `com.apple.idleassetsd`

## Safety & Verdict

- **Safety Level:** **100% Safe to Delete**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - The desktop background falls back to the default static image (or user custom picture).
  - If dynamic wallpaper is selected again in System Settings, macOS initiates download of only that specific video clip on demand.
  - Zero impact on system functionality.
