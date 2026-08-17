# com.apple.replayd

## Status

Do not disable.

`replayd` is required for screenshot / screen capture flows, not only long-form screen recording.

Risk level: 4.

## Purpose

Observed job:

```text
gui/502/com.apple.replayd
/System/Library/LaunchAgents/com.apple.replayd.plist
/usr/libexec/replayd
```

Mach services:

```text
com.apple.replayd
com.apple.replayd-cache-delete
com.apple.replaykit.sharingsession
com.apple.replaykit.sharingsession.notification
com.apple.usernotifications.delegate.com.apple.ReplayKitNotifications
```

Observed before disable:

```text
replayd: ~50 MB RSS
```

## Failed Experiment

2026-06-20: `replayd` was disabled and the machine was rebooted.

Applied:

```bash
launchctl bootout gui/502/com.apple.replayd
launchctl disable gui/502/com.apple.replayd
sudo launchctl disable user/502/com.apple.replayd
sudo launchctl disable user/501/com.apple.replayd
```

Post-reboot state:

```text
replayd process absent.
Normal SSH/network/sudo still worked.
```

User test:

```text
Attempting a normal screenshot froze the GUI.
Mouse still moved, but Dock / screen interaction stopped responding.
```

Logs confirmed direct screenshot dependency:

```text
launchd failed lookup: name = com.apple.replayd, requestor = screencapture, error = 3: No such process
screencapture: capture error could not create image from display
Service "com.apple.xpc.launchd.unmanaged.screencapture.*" tried to register endpoint "com.apple.screencapture.interactive" already registered
```

## Rollback Performed

```bash
launchctl enable gui/502/com.apple.replayd
sudo launchctl enable user/502/com.apple.replayd
sudo launchctl enable user/501/com.apple.replayd
pkill -TERM -x screencapture
pkill -TERM -x screencaptureui
launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.replayd.plist
sudo shutdown -r now
```

After reboot:

```text
com.apple.replayd => enabled
replayd process running
SSH/sudo/network healthy
```

## Decision

Never include `com.apple.replayd` in conservative, coding, or aggressive debloat profiles.

It may be shown only in a protected "do not disable" / dependency reference list.

Reason:

```text
Screenshots are core system functionality.
Disabling replayd can freeze the GUI during screenshot attempts.
```
