# Core Kernel & System Extension Manager — kernelmanagerd

## Basics

- **Main label:** `system/com.apple.kernelmanagerd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.kernelmanagerd.plist`
- **Binary:** `/usr/libexec/kernelmanagerd`
- **Domain:** `system`
- **Category:** `core_macos_kernel_kext_sysext`
- **Risk:** `4` (Critical Core System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`kernelmanagerd` (Kernel Manager Daemon) is Apple's primary system extension and KEXT driver management daemon bound to XNU kernel Host Special Port 15:

1. **Kernel & DriverKit Extension Management**: Builds and validates the Auxiliary Kernel Collection (AuxKC), loading hardware drivers including Wi-Fi DriverKit (`com.apple.DriverKit-AppleBCMWLAN.dext`), audio, storage, and USB drivers.
2. **System Extension Validation (`com.apple.kernelmanagerd.system-extensions`)**: Watches `/Library/Extensions` and coordinates DriverKit system extension lifecycle with `sysextd`.
3. **Kernel Panic Protection (`_PanicOnCrash`)**: Configured with `PanicOnConsecutiveCrash: true`. A failure or crash of this daemon triggers an immediate XNU kernel panic.

## Why It Must Remain Enabled

- Disabling `kernelmanagerd` **triggers an immediate kernel panic** and prevents macOS from loading hardware drivers (Wi-Fi, storage, audio).

## Status

**KEPT ENABLED AND PROTECTED.**
