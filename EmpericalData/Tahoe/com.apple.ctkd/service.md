# CryptoTokenKit SmartCard & Token Hosting Stack — ctkd & ctkahp

## Basics

- **Main labels:** `gui/<uid>/com.apple.ctkd`, `gui/<uid>/com.apple.ctkbind`, `gui/<uid>/com.apple.CryptoTokenKit.ahp.agent`, `system/com.apple.ctkd`, `system/com.apple.CryptoTokenKit.ahp`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.ctkd.plist`, `/System/Library/LaunchAgents/com.apple.ctkbind.plist`, `/System/Library/LaunchAgents/com.apple.CryptoTokenKit.ahp.agent.plist`, `/System/Library/LaunchDaemons/com.apple.ctkd.plist`, `/System/Library/LaunchDaemons/com.apple.CryptoTokenKit.ahp.plist`
- **Binaries:** `/System/Library/Frameworks/CryptoTokenKit.framework/ctkd`, `/System/Library/Frameworks/CryptoTokenKit.framework/ctkahp.bundle/Contents/MacOS/ctkahp`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `security_smartcards_cryptotokenkit`
- **Risk:** `1` (for users without physical PIV/CAC SmartCards or SmartCard-mode YubiKeys)
- **Verdict:** `disable for coding profile`

## What It Does

`ctkd` and `ctkahp` manage macOS CryptoTokenKit (`CryptoTokenKit.framework`) SmartCard hardware token drivers:

1. **SmartCard Reader & Slot Registry (`com.apple.ctkd.slot-registry`)**: Scans USB ports and card readers for physical SmartCard hardware (PIV / CAC / SmartCard-mode YubiKey).
2. **Token Extension Hosting (`ctkahp` / `com.apple.CryptoTokenKit.ahp`)**: Hosts isolate CryptoTokenKit token extensions for reading hardware private keys and digital certificates.

## What Is NOT Affected

- **Touch ID, Password Auth & SSH Keys**: Standard password login, Touch ID, SSH keys (`id_ed25519`, `id_rsa`), Git, VSCode, Terminal, Docker, SSH, Wi-Fi, and sound operate **100% normally**. *(WebAuthn/FIDO2 browser auth relies on `LocalAuthentication`, not `ctkd` SmartCards).*
- **Massive RAM Savings**: Eliminates a cluster of 4 background processes (`ctkahp` x2, `ctkd` x2), freeing **~45.5MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.ctkd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ctkd"
launchctl bootout "gui/$uid/com.apple.ctkbind" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ctkbind"
launchctl bootout "gui/$uid/com.apple.CryptoTokenKit.ahp.agent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.CryptoTokenKit.ahp.agent"
sudo launchctl bootout system/com.apple.ctkd 2>/dev/null || true
sudo launchctl disable system/com.apple.ctkd
sudo launchctl bootout system/com.apple.CryptoTokenKit.ahp 2>/dev/null || true
sudo launchctl disable system/com.apple.CryptoTokenKit.ahp
sudo killall ctkahp ctkd 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.ctkd"
launchctl enable "gui/$uid/com.apple.ctkbind"
launchctl enable "gui/$uid/com.apple.CryptoTokenKit.ahp.agent"
sudo launchctl enable system/com.apple.ctkd
sudo launchctl enable system/com.apple.CryptoTokenKit.ahp
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.ctkd`, `gui/502/com.apple.ctkbind`, `gui/502/com.apple.CryptoTokenKit.ahp.agent`, `system/com.apple.ctkd`, and `system/com.apple.CryptoTokenKit.ahp`.
2. All 4 processes (`ctkahp` root/user, `ctkd` system/user) terminated, releasing **~45.5MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - All 4 `ctk` & `ctkahp` processes remain stopped permanently (`pgrep -fl "ctkd|ctkahp"` -> 0).
   - Touch ID, SSH keys, password auth, and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
