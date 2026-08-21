# com.apple.CodeSigningHelper

## Basics

- **Process names:** `com.apple.CodeSigningHelper`
- **Domain:** `system (XPCService)`
- **Bundle Path:** `/System/Library/Frameworks/Security.framework/Versions/A/XPCServices/com.apple.CodeSigningHelper.xpc`
- **Binary:** `/System/Library/Frameworks/Security.framework/Versions/A/XPCServices/com.apple.CodeSigningHelper.xpc/Contents/MacOS/com.apple.CodeSigningHelper`
- **Category:** `security_code_signing_validation`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System Code Signing & Entitlements Verification Helper (`Security.framework` / `libsecurity_codesigning.dylib`).
Responsible for:
1. **Mach-O Binary Code Signature Validation**: Verifies developer certificates, Ad-hoc signatures, CDHash digests, and `_CodeSignature/CodeResources` when binaries and app bundles are executed.
2. **Process Entitlement Verification**: Inspects and validates process entitlements for TCC permissions (Microphone, Camera, Disk Access) and Sandbox enforcement.
3. **Authorization Services Validation**: Validates caller entitlements during privileged helper tool execution (relied upon by ExtremeMacTweaker's `RootTweakAction`).

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~7.9 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical core OS security component. Disabling or tampering with it causes process execution termination (SIGKILL / invalid signature), Gatekeeper validation failure, and broken TCC / Authorization Services.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Mandatory Code Execution Security Infrastructure)**.
