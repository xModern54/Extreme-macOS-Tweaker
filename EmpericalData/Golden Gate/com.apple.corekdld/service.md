# com.apple.corekdld

## Basics

- **Process names:** `corekdld`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.corekdld.plist`
- **Binary:** `/System/Library/PrivateFrameworks/CoreKDL.framework/Support/corekdld`
- **Category:** `security_applepay_fairplay_kext_denylist`
- **Risk:** `2` (Conditional for Apple Pay / FairPlay DRM streaming)
- **Verdict:** `disable-for-coding`

## Notes

What it does:
CoreKDL Security Bridge & Kernel Data Loader Daemon (`CoreKDL.framework` / `corekdld`).
Responsible for:
1. **Apple Pay & FairPlay DRM Hardware Bridge**: Provides cryptographic kernel token validation for Apple Pay web/app transactions and Apple TV+ / iTunes FairPlay DRM protected playback.
2. **Kext Denylist Asset Loader (`CoreKDLDriver`)**: Listens for `com.apple.MobileAsset.KextDenyList.ma.new-asset-installed` notifications and feeds revoked KEXT certificate digests into the `CoreKDLDriver` kernel extension.
3. **Bridge Remote XPC (`com.apple.CoreKDL.remoteXPC`)**: Communicates with Secure Enclave / BridgeOS coprocessor over remote service discovery channels.

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~5.9 MB RAM, 0.0% CPU.

Needed for coding / system:
No. Standard web browsing, YouTube/Netflix streaming (Widevine), audio, video codecs, terminal compilers, and system stability operate 100% normally. Required only if using Apple Pay on the Mac or Apple TV+ FairPlay DRM.

Disable:
```bash
sudo launchctl bootout system/com.apple.corekdld 2>/dev/null || true
sudo launchctl disable system/com.apple.corekdld
```

Rollback:
```bash
sudo launchctl enable system/com.apple.corekdld
sudo launchctl bootstrap system /System/Library/LaunchDaemons/com.apple.corekdld.plist
```

Test result:
Tested on macOS 27 Golden Gate. Safely booted out and disabled. System operates cleanly with 0 log errors or retry loops.
Verdict: **SAFE TO DISABLE FOR CODING / LEAN PROFILES (Risk 2)**.
