# Kerberos & GSSAPI Authentication Stack — digest-service & GSSCred

## Basics

- **Main labels:** `system/com.apple.Kerberos.digest-service`, `system/com.apple.GSSCred`, `system/com.apple.gssd`
- **Plist paths:** `/System/Library/LaunchDaemons/com.apple.Kerberos.digest-service.plist`, `/System/Library/LaunchDaemons/com.apple.GSSCred.plist`, `/System/Library/LaunchDaemons/com.apple.gssd.plist`
- **Binaries:** `/System/Library/PrivateFrameworks/Heimdal.framework/Helpers/digest-service`, `/System/Library/Frameworks/GSS.framework/Helpers/GSSCred`, `/usr/libexec/gssd`
- **Domain:** `system`
- **Category:** `auth_security_kerberos_gssapi`
- **Risk:** `1` (for standalone personal Macs without Active Directory domains)
- **Verdict:** `disable for coding profile`

## What It Does

`digest-service`, `GSSCred`, and `gssd` form Apple's single sign-on (SSO) domain authentication stack:

1. **`digest-service` (`org.h5l.ntlm-service`)**: Calculates NTLM and HTTP Digest MD5/SHA256 authentication hashes for Windows Active Directory and LDAP corporate networks.
2. **`GSSCred` (`com.apple.GSSCred`)**: Caches Kerberos Ticket Granting Tickets (TGT) and GSSAPI session credentials for domain network shares (SMB/AFP) and Exchange servers.
3. **`gssd`**: Generic Security Services Daemon managing GSSAPI authentication contexts.

## What Is NOT Affected

- **Local Authentication & Standalone Operation**: Local user login, `sudo`, Touch ID, Keychain, Wi-Fi, SSH, Git, Docker, Terminal, and web browsers function **100% normally**.
- **System Performance**: Saves **~34MB RSS RAM** and eliminates unused domain authentication daemons.

## Disable

```bash
for label in com.apple.Kerberos.digest-service com.apple.GSSCred com.apple.gssd; do
  sudo launchctl bootout "system/$label" 2>/dev/null || true
  sudo launchctl disable "system/$label"
done
```

## Rollback

```bash
for label in com.apple.Kerberos.digest-service com.apple.GSSCred com.apple.gssd; do
  sudo launchctl enable "system/$label"
done
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.Kerberos.digest-service`, `system/com.apple.GSSCred`, and `system/com.apple.gssd`.
2. Processes `digest-service` and `GSSCred` terminated, releasing **~34MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - Kerberos and GSS processes remain stopped (`pgrep -fl "digest-service|GSSCred|gssd"` -> 0).
   - System stability and network connectivity operate normally.
   - Log audit confirmed 0 errors or retry loops.
