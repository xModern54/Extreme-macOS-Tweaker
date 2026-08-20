# AppSSO / Platform SSO

## Basics

- **Main labels:** `com.apple.AppSSOAgent`, `com.apple.AppSSODaemon`
- **Related label:** `com.apple.AppSSOAgent.login`
- **Processes:** `AppSSOAgent`, `AppSSODaemon`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `auth_enterprise_sso`
- **Risk:** `2`
- **Verdict:** `likely safe for non-enterprise coding setup`

## What It Does

Apple App SSO / Platform SSO infrastructure.

This is mainly for managed enterprise or school environments, identity providers, Kerberos extension flows, Platform SSO login integration, and apps that use Apple's Extensible SSO stack.

For a personal coding Mac that does not use enterprise SSO, MDM login SSO, corporate Kerberos, or school/work identity integration, this looks removable from the active background set.

## Observed Cost

Observed on 2026-06-20 under `codexadmin`:

```text
AppSSOAgent   ~45 MB RSS
AppSSODaemon  ~23 MB RSS
```

Total observed idle RSS: about `68 MB`.

## Launchd Labels

```text
gui/<uid>/com.apple.AppSSOAgent
system/com.apple.AppSSODaemon
system/com.apple.AppSSOAgent.login
```

Known XPC endpoints:

```text
com.apple.AppSSO.service-xpc
com.apple.PlatformSSO.service-xpc
com.apple.PlatformSSO.daemon-xpc
com.apple.PlatformSSO.login.service-xpc
com.apple.PlatformSSO.service-login-manager-xpc
com.apple.PlatformSSO.settings.service-xpc
com.apple.usernotifications.delegate.com.apple.PlatformSSO.notifications
```

## Disable

```bash
uid=$(id -u)

launchctl bootout gui/$uid/com.apple.AppSSOAgent 2>/dev/null || true
launchctl disable gui/$uid/com.apple.AppSSOAgent

sudo launchctl bootout system/com.apple.AppSSODaemon 2>/dev/null || true
sudo launchctl disable system/com.apple.AppSSODaemon

sudo launchctl bootout system/com.apple.AppSSOAgent.login 2>/dev/null || true
sudo launchctl disable system/com.apple.AppSSOAgent.login
```

Do not include Kerberos services in this tweak by default. Kerberos is related, but broader than AppSSO and should be tested as a separate feature group.

## Rollback

```bash
uid=$(id -u)

launchctl enable gui/$uid/com.apple.AppSSOAgent
sudo launchctl enable system/com.apple.AppSSODaemon
sudo launchctl enable system/com.apple.AppSSOAgent.login

sudo shutdown -r now
```

## Test Result

2026-06-20: applied persistent disable on the target Mac.

Commands:

```bash
launchctl bootout gui/502/com.apple.AppSSOAgent
launchctl disable gui/502/com.apple.AppSSOAgent

sudo launchctl bootout system/com.apple.AppSSODaemon
sudo launchctl disable system/com.apple.AppSSODaemon

sudo launchctl disable system/com.apple.AppSSOAgent.login
```

Immediate result:

```text
AppSSOAgent process absent.
AppSSODaemon process absent.
Disabled overrides present in gui/502 and system domains.
```

Post-reboot result:

```text
AppSSOAgent process absent.
AppSSODaemon process absent.
com.apple.AppSSOAgent => disabled
com.apple.AppSSODaemon => disabled
com.apple.AppSSOAgent.login => disabled
SSH/network/route check OK.
No AppSSO/PlatformSSO log noise observed after boot.
```

## Expected Breakage

Disables Apple SSO / Platform SSO functionality:

```text
Enterprise SSO extensions
Platform SSO login integration
Managed identity provider flows
Corporate/school SSO features
Some Kerberos extension integration triggers
```

Expected impact for current coding-only profile:

```text
Low, if the Mac is not managed by MDM and does not use enterprise SSO.
```
