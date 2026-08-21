# com.apple.AppleDeviceQueryService

## Basics

- **Process names:** `AppleDeviceQueryService`
- **Domain:** `pid/<pid> (XPCService)`
- **Bundle Path:** `/System/Library/PrivateFrameworks/AppleDeviceQuerySupport.framework/Versions/A/XPCServices/AppleDeviceQueryService.xpc`
- **Binary:** `/System/Library/PrivateFrameworks/AppleDeviceQuerySupport.framework/Versions/A/XPCServices/AppleDeviceQueryService.xpc/Contents/MacOS/AppleDeviceQueryService`
- **Category:** `hardware_audio_biometric_drivers`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Low-level hardware device property and capability query XPC service (`AppleDeviceQuerySupport.framework`).
Spawned as child XPC instances by:
1. `coreaudiod` (macOS audio engine) — queries built-in speaker calibrations, microphone array configurations, DAC/codec chips, and supported audio sample rates in IOKit / DeviceTree.
2. `biometrickitd` (Touch ID daemon) — queries fingerprint sensor hardware revision, serial number, and Secure Enclave pairing status.

Why we looked at it:
Observed running in process table under `_coreaudiod` and `root`.

Resource footprint:
2 instances consume ~9 MB RAM total, 0.0% CPU.

Needed for coding / system:
Yes. Disabling or removing breaks audio initialization in `coreaudiod` and Touch ID biometric authentication in `biometrickitd`.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4)**.
Hardware driver integration layer for audio output and Touch ID.
