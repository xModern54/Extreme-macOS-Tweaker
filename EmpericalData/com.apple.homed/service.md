# HomeKit / Home

## Basics

- **Main labels:** `com.apple.homed`, `com.apple.homeeventsd`, `com.apple.homeenergyd`
- **Related labels:** `com.apple.ThreadCommissionerService`, `com.apple.threadradiod`
- **Processes:** `homed`, `homeeventsd`, `homeenergyd`, `CoreThreadCommissionerServiced`, `threadradiod`, Home widgets
- **Domains:** `gui/<uid>`, `system`
- **Category:** `homekit`
- **Risk:** `1-2`
- **Verdict:** `disable for coding profile`

## What It Does

HomeKit/Home app support: smart home state, Home events, Home energy features, Home widgets, Matter support, Thread commissioning/radio support, Home notifications, Home app intents, and background sync/event tasks.

Not needed for this coding-only machine because Home/HomeKit smart devices are not used.

## Working Disable Recipe

Disable the runtime services:

```bash
uid=$(id -u)

for svc in \
com.apple.homed \
com.apple.homeeventsd \
com.apple.homeenergyd \
com.apple.ThreadCommissionerService
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

sudo launchctl disable system/com.apple.threadradiod
sudo launchctl bootout system/com.apple.threadradiod 2>/dev/null || true
```

Optional SSV app removal after `csrutil authenticated-root disable`:

```bash
sudo mkdir -p /System/Volumes/Update/mnt1
sudo mount -o nobrowse -t apfs /dev/diskXsY /System/Volumes/Update/mnt1

sudo mkdir -p /System/Volumes/Update/mnt1/System/Applications.disabled
sudo mv /System/Volumes/Update/mnt1/System/Applications/Home.app \
        /System/Volumes/Update/mnt1/System/Applications.disabled/Home.app

sudo bless --mount /System/Volumes/Update/mnt1 --bootefi --create-snapshot --verbose
sudo reboot
```

Replace `diskXsY` with the real APFS System volume, for example `disk3s3`.

## Rollback

Runtime rollback:

```bash
uid=$(id -u)

for svc in \
com.apple.homed \
com.apple.homeeventsd \
com.apple.homeenergyd \
com.apple.ThreadCommissionerService
do
  launchctl enable gui/$uid/$svc
done

sudo launchctl enable system/com.apple.threadradiod
```

SSV app rollback:

```bash
sudo mkdir -p /System/Volumes/Update/mnt1
sudo mount -o nobrowse -t apfs /dev/diskXsY /System/Volumes/Update/mnt1

sudo mv /System/Volumes/Update/mnt1/System/Applications.disabled/Home.app \
        /System/Volumes/Update/mnt1/System/Applications/Home.app

sudo bless --mount /System/Volumes/Update/mnt1 --bootefi --create-snapshot --verbose
sudo reboot
```

## Verified Result

Tested on 2026-06-19 on Target Mac under `codexadmin`.

Before disable:

```text
homed                           65.5 MB
homeenergyd                     30.9 MB
homeeventsd                     13.9 MB
CoreThreadCommissionerServiced   8.9 MB
HomeEnergyWidgetsExtension       0.2 MB

BEFORE_HOME_RSS: 5 processes, 119.4 MB
```

Temporary `bootout` removed all core HomeKit daemons. The only remaining match was `HomeEnergyWidgetsExtension` launched from the moved `Home.app`; killing it manually removed the last match and it did not immediately return.

Persistent `launchctl disable` survived reboot. After reboot at 14 seconds uptime:

```text
HOME_RSS: 0 processes, 0.0 MB

com.apple.homed => disabled
com.apple.homeeventsd => disabled
com.apple.homeenergyd => disabled
com.apple.ThreadCommissionerService => disabled
com.apple.threadradiod => disabled
```

`Home.app` SSV removal also worked:

```text
/System/Applications/Home.app: missing
/System/Applications.disabled/Home.app: present
Authenticated Root: disabled
System booted normally
SSH returned
```

## Known Launchd Labels

GUI agents:

```text
com.apple.homed
com.apple.homeeventsd
com.apple.homeenergyd
com.apple.ThreadCommissionerService
```

System daemon:

```text
com.apple.threadradiod
```

## Related Endpoints And Payload

Related Mach/XPC endpoints seen under `homed`:

```text
com.apple.homed.xpc
com.apple.homekit.xpc
com.apple.homekit.coredata.xpc
com.apple.homekitevents.xpc
com.apple.homeenergyd.xpc
com.apple.matter.framework.xpc
com.apple.matter.native.xpc
com.apple.matter.support.xpc
com.apple.ThreadNetwork.xpc
com.apple.aps.homekit
com.apple.aps.homeenergyd
com.apple.private.alloy.home-idswake
com.apple.private.alloy.home.invite-idswake
com.apple.usernotifications.delegate.com.apple.Home
com.apple.private.appintents.delegate.com.apple.homed
```

Home app widgets:

```text
com.apple.Home.HomeWidget.Interactive
com.apple.Home.HomeEnergyWidgets
```

Additional physical payload exists in `HomeKit.framework`, `Matter.framework`, `ThreadNetwork.framework`, HomeKit private frameworks, Home app extensions, ExtensionKit extensions, and iOSSupport Home frameworks. These were not physically removed yet except for moving `Home.app`.
