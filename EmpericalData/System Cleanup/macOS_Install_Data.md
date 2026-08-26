# macOS Install Data & Software Update Bundles

## Target Directories

- `/System/Volumes/Data/macOS Install Data`
- `/Library/Updates`
- `/System/Volumes/Data/MobileSoftwareUpdate`
- `/private/var/folders/*/*/*/com.apple.SoftwareUpdate`

## Footprint

- **Typical Size:** `1.2 GB – 12.0+ GB`
- **Observed on Physical Mac:** `1.2 GB` (`/System/Volumes/Data/macOS Install Data/UpdateBundle`)

## What Is Stored Here

- Partial or complete macOS installer packages (`.pkg`, `.dmg`, `.sproduct`, `UpdateBundle`).
- Staged OS deltas downloaded in the background by `softwareupdated` and `MobileSoftwareUpdate`.
- BridgeOS firmware payloads and asset catalogs for staged updates.

## Related Daemons & Agents

- `com.apple.softwareupdated`
- `com.apple.SoftwareUpdateNotificationManager`
- `com.apple.mobileassetd`

## Safety & Verdict

- **Safety Level:** **100% Safe to Delete**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - If Software Update background daemons are **disabled** in Tweaker (e.g. `softwareupdated` disabled): This data is completely dead weight and will **never** be downloaded again.
  - If Software Update is **enabled**: The system will simply query Apple update servers afresh next time the user manually clicks "Check for Updates" in System Settings and download the latest patch from scratch.
  - No system instability or boot issues occur.
