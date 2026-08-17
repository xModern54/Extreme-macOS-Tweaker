# System Temporary Directories & Cache Cleanup Daemon — bsd.dirhelper

## Basics

- **Main label:** `system/com.apple.bsd.dirhelper`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.bsd.dirhelper.plist`
- **Binary:** `/usr/libexec/dirhelper`
- **Domain:** `system`
- **Category:** `system_disk_cache_maintenance`
- **Risk:** `2` (Recommended maintenance daemon for developer machines)
- **Verdict:** `KEPT ENABLED FOR DISK HYGIENE & TMP CLEANUP`

## What It Does

`dirhelper` (BSD Directory Helper) is Apple's automated temporary directory maintenance daemon:

1. **Automated `/tmp` & `/var/tmp` File Purger (`CLEAN_FILES_OLDER_THAN_DAYS=3`)**: Runs nightly at 03:35 AM (`StartCalendarInterval`), scanning `/tmp`, `/var/tmp`, and `/var/folders/` caches to safely remove build artifacts, temporary scripts, and dump files inactive for more than 3 days.
2. **SSD Storage Maintenance**: Prevents compiler build artifacts and temporary files from silently accumulating and consuming gigabytes of NVMe storage space.

## Why It Was Kept Enabled

- Preserves automated night-time temporary file cleanup (`/tmp` / `/var/tmp`), keeping NVMe SSD storage free from abandoned developer build artifacts. Kept enabled per user decision.

## Status

**KEPT ENABLED.**
