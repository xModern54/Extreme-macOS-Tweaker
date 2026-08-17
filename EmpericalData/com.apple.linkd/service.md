# linkd / AppIntents / App Shortcuts Registry

## Basics

- **Main label:** `com.apple.linkd`
- **Related extension:** `com.apple.MobileSMS.MessagesActionExtension`
- **Processes:** `linkd`, app intent extensions launched under `linkd` process domains
- **Domains:** `gui/<uid>`
- **Category:** `appintents_shortcuts_suggestions`
- **Risk:** `2-3`
- **Verdict:** `validated aggressive-profile candidate if App Shortcuts, AppIntents suggestions, and linked entity features are unused`

## What It Does

`linkd` is a per-user Apple service for AppIntents / App Shortcuts registry, suggestions, transcript, linked entities, and extension hosting/mediation.

Observed endpoints:

```text
com.apple.linkd.application-service
com.apple.linkd.autoShortcut
com.apple.linkd.cliSupport
com.apple.linkd.constraints
com.apple.linkd.extension
com.apple.linkd.mediator
com.apple.linkd.observationStatusRegistry
com.apple.linkd.registry
com.apple.linkd.suggestedentities
com.apple.linkd.suggestions
com.apple.linkd.transcript
```

`sudo launchctl procinfo` showed that `MessagesActionExtension` was launched in a `linkd` process domain:

```text
domain = pid/356 [linkd]
serviceName = com.apple.MobileSMS.MessagesActionExtension
extension point = com.apple.appintents-extension
managed_by = com.apple.runningboard
immediate reason = launch job demand
```

This means `linkd` can act as the real launcher/host mediator for AppIntents extensions even when the target extension service name has a disabled override.

## Observed Cost

Observed on 2026-06-20 under `codexadmin`:

```text
linkd                   ~38 MB RSS
MessagesActionExtension ~28 MB RSS
```

Total cost relevant to this investigation: about `66 MB RSS`.

## Disable

```bash
uid=$(id -u)

launchctl bootout gui/$uid/com.apple.linkd 2>/dev/null || true
launchctl disable gui/$uid/com.apple.linkd

# Optional cleanup for already-launched dependent extension processes:
pkill -TERM -f "/System/Applications/Messages.app/Contents/Extensions/MessagesActionExtension.appex" 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)

launchctl enable gui/$uid/com.apple.linkd
sudo shutdown -r now
```

## Test Result

2026-06-20: persistent disable was applied on the target Mac after `MessagesActionExtension` kept returning.

Before:

```text
linkd running
MessagesActionExtension running
Core Messages/iMessage/IDS launchd jobs already disabled
```

Applied:

```bash
launchctl bootout gui/502/com.apple.linkd
launchctl disable gui/502/com.apple.linkd
pkill -TERM -f "/System/Applications/Messages.app/Contents/Extensions/MessagesActionExtension.appex"
```

Immediate result:

```text
linkd absent
MessagesActionExtension absent
No immediate log noise observed
SSH/network/route check OK
```

Post-reboot result:

```text
linkd absent
MessagesActionExtension absent
Disabled override persisted in gui/502.
SSH/network/route check OK.
No related post-boot log noise observed.
Delayed check after boot also stayed clean.
```

## Expected Breakage

Disables or degrades:

```text
App Shortcuts registry
AppIntents linked entity registry
automatic shortcut suggestions
some Siri/Shortcuts/AppIntents integrations
linked entity suggestions
AppIntents transcript/registry maintenance
extensions launched through linkd process domains
```

Expected impact for current coding-only profile:

```text
Acceptable for aggressive profile if Shortcuts, Siri suggestions, AppIntents suggestions, and Apple linked-entity integrations are unused.
```

Do not disable broad infrastructure such as `pkd` or `extensionkitservice` just to solve one extension. They are shared by many app/system extensions.
