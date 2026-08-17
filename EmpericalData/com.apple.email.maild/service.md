# Apple Mail Daemon — email.maild

## Basics

- **Main label:** `gui/<uid>/com.apple.email.maild`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.email.maild.plist`
- **Binary:** `/System/Library/PrivateFrameworks/EmailDaemon.framework/Versions/A/maild`
- **Domain:** `gui/<uid>`
- **Category:** `apple_apps_mail`
- **Risk:** `1` (for non-users of Apple Mail.app)
- **Verdict:** `disable for coding profile`

## What It Does

`maild` (Email Daemon) is the background synchronization engine for Apple's default Mail application (`Mail.app`):

1. **Background Mail Fetch & Push Notifications**: Periodically polls IMAP/Exchange/iCloud servers when `Mail.app` is closed, issuing desktop notifications for new emails.
2. **Scheduled Send Processing (`sendlaterdelivery`)**: Delivers scheduled emails at specified timestamps.
3. **Database Maintenance**: Executes daily maintenance on SQLite mail databases (`ProcessSQLQueryPerformanceData`).

## What Is NOT Affected

- **Webmail & Third-Party Email Clients**: Gmail web interface, Spark, Outlook, Thunderbird, and web browsers function **100% normally**.
- **System Performance & Developer Tools**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, sound, and graphics run without any degradation.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.email.maild" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.email.maild"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.email.maild"
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.email.maild`.
2. Process `maild` terminated, releasing **~20MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `maild` process remains stopped.
   - System stability and network connectivity operate normally.
   - Log audit confirmed 0 errors or retry loops.
