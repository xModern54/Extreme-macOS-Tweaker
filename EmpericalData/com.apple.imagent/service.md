# Messages / iMessage / IDS

## Basics

- **Main label:** `com.apple.imagent`
- **Related labels:** `com.apple.imcore.imtransferagent`, `com.apple.identityservicesd`, `com.apple.idsfoundation.IDSRemoteURLConnectionAgent`, `com.apple.facetimemessagestored`, `com.apple.callhistoryd`, `com.apple.CallHistorySyncHelper`, `com.apple.CallHistoryPluginHelper`, `com.apple.screensharing.MessagesAgent`, `com.apple.MobileSMS.MessagesActionExtension`, `com.apple.linkd`
- **Processes:** `imagent`, `IMTransferAgent`, `identityservicesd`, `facetimemessagestored`, `callhistoryd`, `CallHistorySyncHelper`, `CallHistoryPluginHelper`, `MessagesActionExtension`
- **Domains:** `gui/<uid>`
- **Category:** `messages_imessage_ids`
- **Risk:** `2-3`
- **Verdict:** `validated with linkd disabled`

## What It Does

This group covers the local Messages / iMessage backend and the Apple IDS identity layer used by Messages and related Apple communication features.

Observed roles:

```text
imagent              - IMCore / Messages backend, iMessage endpoints, MobileSMS/iChat notifications
IMTransferAgent      - attachment and transfer handling for Messages/IDS
identityservicesd    - IDS identity service used by iMessage, FaceTime, and Apple ecosystem channels
facetimemessagestored - FaceTime video/message store
callhistoryd         - call history database service
CallHistorySyncHelper - call history sync helper
CallHistoryPluginHelper - call history plugin helper
screensharing.MessagesAgent - Messages-based screen sharing invitation agent
```

`MessagesActionExtension` is an AppIntents / ExtensionKit process from `Messages.app`. It is not backed by a normal plist. `sudo launchctl procinfo` showed it was launched in the process domain of `linkd`:

```text
domain = pid/<pid> [linkd]
serviceName = com.apple.MobileSMS.MessagesActionExtension
```

## Observed Cost

Observed on 2026-06-20 under `codexadmin`:

```text
identityservicesd       ~45 MB RSS
imagent                 ~35 MB RSS
MessagesActionExtension ~25 MB RSS
CallHistoryPluginHelper ~15 MB RSS
IMTransferAgent         ~10 MB RSS
```

Total observed active RSS: about `130 MB`.

The user-provided `xmodern` snapshot showed `imagent` at about `23.3 MB`.

## Launchd Labels

```text
gui/<uid>/com.apple.imagent
gui/<uid>/com.apple.imcore.imtransferagent
gui/<uid>/com.apple.identityservicesd
gui/<uid>/com.apple.idsfoundation.IDSRemoteURLConnectionAgent
gui/<uid>/com.apple.facetimemessagestored
gui/<uid>/com.apple.callhistoryd
gui/<uid>/com.apple.CallHistorySyncHelper
gui/<uid>/com.apple.CallHistoryPluginHelper
gui/<uid>/com.apple.screensharing.MessagesAgent
gui/<uid>/com.apple.MobileSMS.MessagesActionExtension
gui/<uid>/com.apple.linkd
```

Important endpoints:

```text
com.apple.aps.imagent
com.apple.imagent.desktop.auth
com.apple.imagent.cache-delete
com.apple.corespotlight.daemon.messages
com.apple.madrid-idswake
com.apple.madrid.lite-idswake
com.apple.usernotifications.delegate.com.apple.iChat
com.apple.usernotifications.delegate.com.apple.MobileSMS

com.apple.imtransferservices.IMTransferAgent

com.apple.identityservicesd.aps
com.apple.identityservicesd.desktop.auth
com.apple.identityservicesd.idquery.desktop.auth
com.apple.identityservicesd.nsxpc
com.apple.identityservicesd.nsxpc.auth
com.apple.identityservicesd.pds
com.apple.identityservicesd.xpc

com.apple.facetimemessagestored.service
com.apple.facetimemessagestored.videomessaging
com.apple.private.alloy.facetime.messaging-idswake

com.apple.callhistoryd.service
com.apple.conversation.history
com.apple.CallHistorySyncHelper
com.apple.CallHistoryPluginHelper
com.apple.screensharing.MessagesAgent
com.apple.MobileSMS.MessagesActionExtension
com.apple.linkd
```

## Disable

```bash
uid=$(id -u)

for svc in \
com.apple.imagent \
com.apple.imcore.imtransferagent \
com.apple.identityservicesd \
com.apple.idsfoundation.IDSRemoteURLConnectionAgent \
com.apple.facetimemessagestored \
com.apple.callhistoryd \
com.apple.CallHistorySyncHelper \
com.apple.CallHistoryPluginHelper \
com.apple.screensharing.MessagesAgent \
com.apple.MobileSMS.MessagesActionExtension \
com.apple.linkd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
  launchctl disable gui/$uid/$svc
done
```

Do not include `system/com.apple.apsd` in this tweak. `apsd` is the global Apple Push Service daemon and affects many unrelated Apple services.

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.imagent \
com.apple.imcore.imtransferagent \
com.apple.identityservicesd \
com.apple.idsfoundation.IDSRemoteURLConnectionAgent \
com.apple.facetimemessagestored \
com.apple.callhistoryd \
com.apple.CallHistorySyncHelper \
com.apple.CallHistoryPluginHelper \
com.apple.screensharing.MessagesAgent \
com.apple.MobileSMS.MessagesActionExtension \
com.apple.linkd
do
  launchctl enable gui/$uid/$svc
done

sudo shutdown -r now
```

## Test Result

2026-06-20: persistent disable was applied on the target Mac.

Before:

```text
identityservicesd       running
imagent                 running
CallHistoryPluginHelper running
IMTransferAgent         running
MessagesActionExtension running
```

Applied:

```bash
launchctl bootout gui/502/com.apple.imagent
launchctl disable gui/502/com.apple.imagent

launchctl bootout gui/502/com.apple.imcore.imtransferagent
launchctl disable gui/502/com.apple.imcore.imtransferagent

launchctl bootout gui/502/com.apple.identityservicesd
launchctl disable gui/502/com.apple.identityservicesd

launchctl bootout gui/502/com.apple.idsfoundation.IDSRemoteURLConnectionAgent
launchctl disable gui/502/com.apple.idsfoundation.IDSRemoteURLConnectionAgent

launchctl bootout gui/502/com.apple.facetimemessagestored
launchctl disable gui/502/com.apple.facetimemessagestored

launchctl bootout gui/502/com.apple.callhistoryd
launchctl disable gui/502/com.apple.callhistoryd

launchctl bootout gui/502/com.apple.CallHistorySyncHelper
launchctl disable gui/502/com.apple.CallHistorySyncHelper

launchctl bootout gui/502/com.apple.CallHistoryPluginHelper
launchctl disable gui/502/com.apple.CallHistoryPluginHelper

launchctl bootout gui/502/com.apple.screensharing.MessagesAgent
launchctl disable gui/502/com.apple.screensharing.MessagesAgent

launchctl disable gui/502/com.apple.MobileSMS.MessagesActionExtension
```

Immediate result:

```text
imagent absent
IMTransferAgent absent
identityservicesd absent
CallHistoryPluginHelper absent
MessagesActionExtension initially remained as an ExtensionKit process
No immediate log noise observed
SSH/network/route check OK
```

Extension investigation:

```bash
sudo launchctl procinfo <MessagesActionExtension-pid>
```

Key finding:

```text
domain = pid/356 [linkd]
managed_by = com.apple.runningboard
extension point = com.apple.appintents-extension
serviceName = com.apple.MobileSMS.MessagesActionExtension
immediate reason = launch job demand
```

`pluginkit -e ignore` and `launchctl disable gui/502/com.apple.MobileSMS.MessagesActionExtension` alone were not sufficient. The extension returned after a delay.

Final fix:

```bash
launchctl bootout gui/502/com.apple.linkd
launchctl disable gui/502/com.apple.linkd
pkill -TERM -f "/System/Applications/Messages.app/Contents/Extensions/MessagesActionExtension.appex"
```

Post-reboot result:

```text
No Messages/iMessage/IDS launchd processes observed.
No linkd process observed.
MessagesActionExtension did not return after linkd was disabled.
Disabled overrides persisted in gui/502.
SSH/network/route check OK.
No related post-boot log noise observed.
Process count after final boot check: 367.
```

## Expected Breakage

Disables or degrades:

```text
iMessage / Messages backend
Messages attachment transfer
Messages notifications
FaceTime messaging / video message store
Call history sync
Apple IDS identity services
Messages-based screen sharing invitations
Some Apple ecosystem IDS wake channels
```

Expected impact for current coding-only profile:

```text
Acceptable for aggressive profile if iMessage, FaceTime, call history sync, and Apple communication ecosystem features are unused on this Mac.
```
