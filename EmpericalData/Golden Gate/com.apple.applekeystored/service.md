# com.apple.applekeystored

## Basics

- **Process names:** `applekeystored`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.applekeystored.plist`
- **Binary:** `/usr/libexec/applekeystored`
- **Category:** `security_crypto_secure_enclave_keybag`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Apple KeyStore & Secure Enclave Keybag Management Daemon (`applekeystored`).
Interfaces with `AppleKeyStore.kext` and Apple Silicon Secure Enclave (SEP).
Responsible for:
1. **APFS Data Protection & FileVault Key Management**: Handles cryptographic file protection classes (Class A, B, C, D).
2. **Session Lock / Unlock Transition**: Purges Class A encryption keys from system RAM when the screen is locked or the device goes to sleep.
3. **Keybag Unsealing**: Verifies user credentials / Touch ID tokens with Secure Enclave to re-derive session master keys upon unlock.

Why we looked at it:
Found running under root in process table on macOS 27 Golden Gate.

Resource footprint:
~7.0 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical cryptographic infrastructure. Disabling or tampering breaks session unlock, APFS file protection, keychain access, and Secure Enclave hardware authentication.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Fundamental Cryptographic Security Component)**.
