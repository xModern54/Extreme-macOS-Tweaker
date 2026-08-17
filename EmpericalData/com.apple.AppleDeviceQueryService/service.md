# Hardware Serial Number & Component Attribute Query Service — AppleDeviceQueryService

## Basics

- **Main label:** `com.apple.AppleDeviceQueryService`
- **Plist path:** `/System/Library/PrivateFrameworks/AppleDeviceQuerySupport.framework/Versions/A/XPCServices/AppleDeviceQueryService.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/AppleDeviceQuerySupport.framework/Versions/A/XPCServices/AppleDeviceQueryService.xpc/Contents/MacOS/AppleDeviceQueryService`
- **Domain:** `pid/<pid> [biometrickitd]`
- **Category:** `hardware_repair_diagnostics`
- **Risk:** `1`
- **Verdict:** `on-demand XPC service (safe to terminate / cleanup on idle)`

## What It Does

`AppleDeviceQueryService` (Apple Device Query Support XPC Service) is Apple's protected hardware serial number and component attribute query engine (`MobileGestalt`):

1. **Hardware Module Serial Number Reader (`MobileGestalt`)**: Queries factory serial numbers, MAC addresses, and component IDs across hardware subsystems:
   - `ScreenSerialNumber` / `DisplayDriverICChipID` (Display panel & driver IC IDs)
   - `FrontFacingCameraModuleSerialNumber` / `RearFacingCamera...` (Camera serial numbers)
   - `BluetoothAddress` / `WifiAddress` (Radio MAC addresses)
   - `MLBSerialNumber` (Motherboard logic board serial number)
   - `MesaSerialNumber` (Touch ID sensor serial number)

## Architecture & Lifecycle Notes

- **Dynamic On-Demand XPC Lifecycle**: `AppleDeviceQueryService` is spawned dynamically inside `domain = pid/<pid> [biometrickitd]` when biometric or diagnostic tools query hardware serial numbers. It exits under memory pressure or can be safely killed without impacting Touch ID, cameras, or system operation.

## Status

**DOCUMENTED AS ON-DEMAND XPC SERVICE.**
