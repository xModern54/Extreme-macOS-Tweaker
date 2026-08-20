# Background Task & Login Items Notification Agent — backgroundtaskmanagementd

## Basics

- **Main labels:** `gui/<uid>/com.apple.backgroundtaskmanagement.agent`, `system/com.apple.backgroundtaskmanagementd`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.backgroundtaskmanagement.agent.plist`, `/System/Library/LaunchDaemons/com.apple.backgroundtaskmanagementd.plist`
- **Binaries:** `/System/Library/PrivateFrameworks/BackgroundTaskManagement.framework/Resources/backgroundtaskmanagementd`, `/System/Library/PrivateFrameworks/BackgroundTaskManagement.framework/Support/BackgroundTaskManagementAgent.app`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `system_background_tasks_notifications`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`backgroundtaskmanagementd` and `BackgroundTaskManagementAgent` manage background login item notifications and weekly startup telemetry:

1. **Background Item Addition Banners**: Triggers system notification banners whenever an application registers new background agents/daemons (*"App X added items that can run in the background"*).
2. **Weekly Startup Telemetry (`LoginItems.analytics`)**: Collects weekly analytics reports containing active login items and sends them to Apple.
3. **Login Items Management UI**: Renders background permission toggles in System Settings -> General -> Login Items.

## What Is NOT Affected

- **Application Auto-Start Execution**: Automatic application launch on boot (driven directly by `launchd` and `loginwindow`) operates **100% normally**.
- **System Performance & Developer Tools**: Xcode, Terminal, Git, Docker, SSH, Wi-Fi, sound, and browsers run without any degradation.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.backgroundtaskmanagement.agent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.backgroundtaskmanagement.agent"
sudo launchctl bootout system/com.apple.backgroundtaskmanagementd 2>/dev/null || true
sudo launchctl disable system/com.apple.backgroundtaskmanagementd
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.backgroundtaskmanagement.agent"
sudo launchctl enable system/com.apple.backgroundtaskmanagementd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.backgroundtaskmanagement.agent` and `system/com.apple.backgroundtaskmanagementd`.
2. Processes `backgroundtaskmanagementd` and `BackgroundTaskManagementAgent` terminated, releasing **~18MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 12 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `backgroundtaskmanagementd` processes remain stopped.
   - Login startup applications and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
