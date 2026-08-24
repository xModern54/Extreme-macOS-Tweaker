# com.apple.diskarbitrationd / com.apple.DiskArbitrationAgent

## Basics

- **Process names:** `diskarbitrationd`, `DiskArbitrationAgent`
- **Domain:** `system` (`com.apple.diskarbitrationd`), `gui/<uid>` (`com.apple.DiskArbitrationAgent`)
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.diskarbitrationd.plist`
  - `/System/Library/LaunchAgents/com.apple.DiskArbitrationAgent.plist`
- **Binary:** `/usr/libexec/diskarbitrationd`, `/System/Library/Frameworks/DiskArbitration.framework/Versions/A/Support/DiskArbitrationAgent`
- **Category:** `core_storage_disk_arbitration_mounting`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Core Darwin/macOS Disk Arbitration & Storage Volume Mounting Daemon (`DiskArbitration.framework` / `diskarbitrationd`).
Responsible for:
1. **Disk Probing & Auto-Mounting**: Listens for IOKit block device attachment events (`IOMedia` — internal NVMe, USB flash drives, external Thunderbolt SSDs, SD cards, DMG/ISO images), probes filesystem headers (APFS, HFS+, ExFAT, FAT32), launches filesystem drivers (`mount_apfs`, `apfs.util`, `mount_msdos`), and mounts volumes to `/Volumes/<Name>`.
2. **Safe Ejection & Disk Claiming**: Arbitrates concurrent access to block devices; coordinates volume unmounting, filesystem cache flushing, and safe device ejection for Finder, Disk Utility, and terminal commands.
3. **Backend for Disk Management Tools**: Core IPC server for `diskutil`, `hdiutil`, Disk Utility, Time Machine, and ExtremeMacTweaker's `RootTweakAction`.

Why we looked at it:
Found running under root in process table on macOS 27 Golden Gate.

Why it must NOT be disabled:
Disabling `diskarbitrationd` **completely breaks all storage disk mounting, external drives, DMG mounting, Disk Utility, and `diskutil` commands** across the entire operating system (`Unable to find DiskArbitration server`).

Resource footprint:
~4.6 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Mandatory core Darwin storage infrastructure.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Fatal Storage Subsystem)**.
