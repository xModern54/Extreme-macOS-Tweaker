# Bluetooth Cloud Pairing & Audio Accessory Bridge — `com.apple.BTServer.cloudpairing` (DO NOT DISABLE)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Core Audio & Bluetooth Accessory Bridge                       |
| Category      | `protected_system_stack` / `audio_bluetooth_bridge`           |
| Risk Level    | **4 — CRITICAL: Disabling causes `audiomxd` 65-85% CPU stormlock** |
| Profile       | **PROTECTED — KEEP ENABLED ALWAYS**                           |
| Verdict       | **NEVER DISABLE / REMOVE FROM ALL TWEAK LISTS**               |

- **Main label:** `gui/<uid>/com.apple.BTServer.cloudpairing`
- **Plist:** `/System/Library/LaunchAgents/com.apple.cloudpaird.plist` (in macOS 27)
- **Binary:** `/System/Library/CoreServices/audioaccessoryd`
- **Domain:** `gui/<uid>`
- **Mach Services:**
  - `com.apple.AudioAccessoryServices`
  - `com.apple.BTServer.cloudpairing`
  - `com.apple.AccessoryServices`
  - `com.apple.BluetoothServices`

## Why It Must NEVER Be Disabled (Причина запрета на отключение)

When `com.apple.BTServer.cloudpairing` (`audioaccessoryd`) is disabled:
1. The `com.apple.AudioAccessoryServices` Mach port becomes unavailable.
2. The core macOS audio daemon **`audiomxd` (MediaExperience)** immediately enters an aggressive, infinite retry loop:
   ```text
   MXAudioAccessoryServices handleServerDeath
     → initializeAudioAccessoryConnection
       → BTAudioRoutingRequest _ensureXPCStarted
         → xpc_connection_bootstrap_look_up_slow (dead service)
   ```
3. **Observed System Degradation:**
   * `audiomxd` burns **~65–85% CPU** continuously in `Rs` (spinlock) state.
   * `launchd` (PID 1) burns **~30% CPU**.
   * `configd` burns **~21% CPU**.
   * `logd` burns **~7% CPU** handling log storm.
   * Total system load hits **~120% CPU** for hours, draining battery and heating up the Mac.

## Test Result & Resolution

**Date:** 2026-08-22  
**Target:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)

* **Test A:** Disabled `bluetoothuserd` only (with `cloudpairing` running) $\to$ `audiomxd` stayed at **0.0% CPU**, system completely quiet.
* **Test B:** Disabled `cloudpairing` only $\to$ `audiomxd` instantly spiked to **64.6% CPU** + `launchd` 29.8% + `configd` 21.0%.
* **Fix Applied:** Removed `cloudpaird` (`com.apple.BTServer.cloudpairing`) from all tweak catalogs. The `bluetooth-user` tweak group now targets **only `bluetoothuserd`**.
