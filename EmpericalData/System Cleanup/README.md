# System Cleanup & Storage Eradication (macOS 15–27)

## Overview

This empirical research catalog documents macOS dynamic storage consumers located on `/System/Volumes/Data` and user directories. It classifies which directories can be safely purged, what mechanisms generate them, their typical disk footprint, and their dependency on background `launchd` services.

---

## 🎯 Classification Matrix

| Tier | Category | Safety | Behavior on Deletion | Typical Size |
| :--- | :--- | :--- | :--- | :--- |
| **Tier 1** | **macOS Update Data** | **100% Safe** | Deleted permanently. Re-downloads only if Software Update is manually triggered. | `1.2 GB – 12.0 GB` |
| **Tier 1** | **Aerial & Dynamic Wallpapers** | **100% Safe** | Videos purged. Static default restored. Re-downloads on explicit preview. | `0.5 GB – 15.0 GB` |
| **Tier 1** | **Diagnostic Reports & Logs** | **100% Safe** | Old crash dumps and trace logs removed. Fresh logs created as needed. | `200 MB – 2.0 GB` |
| **Tier 1** | **User & System Caches** | **100% Safe** | Temporary cache files cleared. Active apps rebuild required items. | `1.0 GB – 10.0 GB` |
| **Tier 2** | **Sleepimage & VM Hibernation** | **Safe (with tweak)** | `hibernatemode 0` prevents re-creation. Frees equal to RAM size immediately. | `2.0 GB – 16.0+ GB` |
| **Tier 2** | **Spotlight Search Indexes** | **Safe (if disabled)** | If `com.apple.metadata.mds` is disabled, freed permanently. If enabled, re-indexes. | `300 MB – 5.0 GB` |
| **Tier 2** | **MobileAsset / AssetsV2 (AI & Siri)** | **Safe (if disabled)** | If Siri/Speech/Intelligence disabled, never re-downloads. If enabled, fetches on demand. | `1.4 GB – 4.0 GB` |
| **Tier 2** | **Biome, Duet & Trial Telemetry** | **Safe (if disabled)** | Local AI telemetry wiped. If services disabled, databases remain empty. | `300 MB – 1.5 GB` |
| **Tier 3** | **Critical Authentication & System DB** | ⛔ **CRITICAL / DO NOT TOUCH** | Deleting destroys user login, authorization rights (`auth.db`), or kernel cryptex. | *Variable* |

---

## 📂 Catalog Directory Reference

1. [`macOS_Install_Data.md`](./macOS_Install_Data.md) — `/System/Volumes/Data/macOS Install Data/`, `/Library/Updates/`, `/System/Volumes/Data/MobileSoftwareUpdate/`
2. [`Sleepimage_and_VM.md`](./Sleepimage_and_VM.md) — `/private/var/vm/sleepimage`, `/private/var/vm/swapfile*`
3. [`System_Assets_MobileAsset.md`](./System_Assets_MobileAsset.md) — `/System/Volumes/Data/System/Library/AssetsV2/`, `PreinstalledAssetsV2/`
4. [`Wallpaper_and_ScreenSavers.md`](./Wallpaper_and_ScreenSavers.md) — `~/Library/Application Support/com.apple.wallpaper/`, `/Library/Application Support/com.apple.idleassetsd/`
5. [`Spotlight_Metadata_Indexes.md`](./Spotlight_Metadata_Indexes.md) — `/.Spotlight-V100/`, `~/Library/Metadata/CoreSpotlight/`
6. [`Telemetry_Biome_and_Intelligence.md`](./Telemetry_Biome_and_Intelligence.md) — `~/Library/Biome/`, `~/Library/DuetExpertCenter/`, `~/Library/IntelligencePlatform/`, `~/Library/Trial/`
7. [`Diagnostics_and_Crash_Logs.md`](./Diagnostics_and_Crash_Logs.md) — `/Library/Logs/DiagnosticReports/`, `~/Library/Logs/`, `/private/var/log/`
8. [`Caches_and_Darwin_Temp.md`](./Caches_and_Darwin_Temp.md) — `~/Library/Caches/`, `/Library/Caches/`, `/private/var/folders/`
9. [`Critical_System_Components_DoNotTouch.md`](./Critical_System_Components_DoNotTouch.md) — `/private/var/db/dslocal/`, `auth.db`, `TCC.db`, `Keychains/`, `Cryptex/`
