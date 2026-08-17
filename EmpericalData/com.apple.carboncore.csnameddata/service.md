# CoreServices CarbonCore Named Data Server — csnameddatad

## Basics

- **Main label:** `user/<uid>/com.apple.carboncore.csnameddata`
- **Plist path:** `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/XPCServices/csnameddatad.xpc`
- **Binary:** `/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/CarbonCore.framework/Versions/A/XPCServices/csnameddatad.xpc/Contents/MacOS/csnameddatad`
- **Domain:** `user/<uid>`
- **Category:** `core_macos_coreservices`
- **Risk:** `4` (Critical System Infrastructure)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`csnameddatad` (CoreServices CarbonCore Named Data Daemon) is Apple's CarbonCore inter-process shared memory and named data resource daemon (`CoreServices.framework` / `CarbonCore.framework`):

1. **Inter-Process Shared Memory & Named Resource Server (`CSNamedData`)**: Provides shared memory allocation, named atomic semaphores, and inter-process resource registration for CoreServices and AppKit applications without disk I/O.
2. **Pressured Exit Support**: Supports `pressured-exit capable: true` to yield RAM (~3.7MB RSS) during system memory pressure events.

## Why It Must Remain Enabled

- Disabling `csnameddatad` **causes application crashes across macOS when calling core `CoreServices` and `CarbonCore` framework functions (`CSNamedData` XPC connection failure)**.
- Explicitly protected in `AGENTS.md` core system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
