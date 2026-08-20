# Safari AutoFill & Passkeys Core Agent — AuthenticationServicesAgent

## Basics

- **Main label:** `gui/<uid>/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent.plist`
- **Binary:** `/System/Cryptexes/App/usr/libexec/AuthenticationServicesAgent`
- **Domain:** `gui/<uid>`
- **Category:** `security_auth_passkeys`
- **Risk:** `2` (Conditional — disables Safari AutoFill & Passkeys)
- **Verdict:** `conditional — disable only if NOT using Safari AutoFill / Passkeys`

> [!IMPORTANT]
> **Условие включения в профиль (Спорно)**: Отключать **ИСКЛЮЧИТЕЛЬНО** на машинах разработчиков, где пользователь **100% не использует встроенный браузер Safari** для автозаполнения сохраненных логинов/паролей из Keychain и для логина по Passkeys (WebAuthn). При использовании Chrome/Firefox/1Password агент не требуется. При активном использовании Safari AutoFill — оставить включенным!

## What It Does

`AuthenticationServicesAgent` manages Safari web credential AutoFill and modern FIDO2 Passkeys authentication:

1. **Safari & App Password AutoFill (`com.apple.AuthenticationServices.AutoFill`)**: Presents stored credential suggestions over input fields in Safari and system web views.
2. **Passkeys & WebAuthn Authentication (`CredentialExchange`)**: Handles FIDO2 Touch ID passwordless authentication on websites.
3. **iCloud Password Sharing Groups (`CredentialSharingGroups`)**: Syncs shared password vaults across family/contacts in iCloud.

## What Is NOT Affected

- **System Authentication & Keychain Core**: System user login, `sudo`, Touch ID unlock, terminal authentication, SSH keys, Git tokens, and `secd` Keychain access function **100% normally**.
- **Third-Party Password Managers & Browsers**: Chrome, Firefox, 1Password, Bitwarden, VSCode, Terminal, Docker, and SSH operate without any issues.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.AuthenticationServicesCore.AuthenticationServicesAgent`.
2. Process `AuthenticationServicesAgent` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `AuthenticationServicesAgent` process remains stopped.
   - System login, `sudo`, Keychain, and non-Safari browsers operate normally.
   - Log audit confirmed 0 errors or retry loops.
