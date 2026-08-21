# com.apple.SecurityAgent

## Basics

- **Process names:** `SecurityAgent`
- **Domain:** `system / authorizationhost (MachServices)`
- **Bundle Path:** `/System/Library/Frameworks/Security.framework/Versions/A/MachServices/SecurityAgent.bundle`
- **Binary:** `/System/Library/Frameworks/Security.framework/Versions/A/MachServices/SecurityAgent.bundle/Contents/MacOS/SecurityAgent`
- **Category:** `security_authentication_ui`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
System authentication and authorization GUI dialog host (`SFAgentApp` / `NSUIElement`).
Responsible for rendering:
1. Administrator password prompts ("App wants to make changes...").
2. Touch ID biometric authentication prompts.
3. Login keychain (`login.keychain-db`) decryption during system startup and auto-login.
4. Authorization Services privilege escalation dialogs (used by ExtremeMacTweaker to elevate root helper).

Why we looked at it:
Observed spawning during cold boot/startup, taking ~180–200 MB RAM initially, and then quickly disappearing from process list.

Why it behaves this way:
It is an ephemeral on-demand agent (`NSDisablePersistence = true`). It loads AppKit, LocalAuthentication, Touch ID/BiometricsKit, and SkyLight rendering frameworks on startup to verify session credentials, unseal login keychain, and then immediately exits (`exit 0`), releasing all 200 MB RAM back to the operating system.

Needed for coding:
Yes. Required for Authorization Services privilege escalation (sudo / Touch ID prompts in Xcode, Terminal, and Tweaker).

Verdict:
**DO NOT TOUCH / KEEP ENABLED**.
Does not consume RAM in background idle state.
