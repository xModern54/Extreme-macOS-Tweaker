# com.apple.chronod

## Purpose

`chronod` is the ChronoCore / WidgetKit user agent. It maintains the widget/control descriptor catalog and launches widget `.appex` processes through ExtensionKit, runningboardd, and launchd.

Observed path:

```text
/System/Library/PrivateFrameworks/ChronoCore.framework/Support/chronod
```

Launchd job:

```text
gui/502/com.apple.chronod
/System/Library/LaunchAgents/com.apple.chronod.plist
```

Mach services include:

```text
com.apple.chronoservices
com.apple.chrono.widgetcenterconnection
com.apple.chrono.controlcenter
com.apple.chronod.replicator
com.apple.aps.chrono.PushNotifications
```

## Why Disable

The target workflow does not use macOS widgets. `chronod` starts immediately after login and launches idle widget extensions even when no widgets are placed on screen.

Observed widget processes started by this stack:

```text
WeatherWidget
StocksWidget
PodcastsWidget
JournalWidgets
JournalWidgetsSecure
WorldClockWidget
FindMyWidgetPeople
FindMyWidgetItems
ScreenTimeWidgetExtension
ScreenTimeWidgetIntentsExtension
BatteriesAvocadoWidgetExtension
RecordWidgetExtension
VoiceMemosSettingsWidgetExtension
```

## Applied

Test bootout:

```bash
launchctl bootout gui/502/com.apple.chronod
```

Persistent disable for `codexadmin`:

```bash
launchctl disable gui/502/com.apple.chronod
```

## Result

Before bootout:

```text
chronod: ~61 MB RSS
widget .appex stack: roughly 500+ MB RSS
```

After bootout:

```text
No chronod process.
No widget .appex processes in the checked widget filter.
NotificationCenter and ControlCenter stayed running.
```

Process count after disable:

```text
process_count=480
total_rss_mb=8523.5
```

## Risk

Risk level: 2.

Expected breakage:

```text
desktop widgets
Notification Center widgets
WidgetKit timelines
some Control Center / Settings widget controls
ChronoCore push/update replication
```

Not expected to break:

```text
boot
login
SSH
Finder
Dock
basic Control Center process startup
```

Reboot validation passed on 2026-06-20.

After reboot:

```text
com.apple.chronod remains disabled.
launchctl print gui/502/com.apple.chronod -> service not found.
No chronod process.
No widget .appex processes in the checked widget filter.
SSH, sudo, default route, Finder, Dock, ControlCenter, and NotificationCenter remained alive.
```

Observed after ~2 minutes uptime:

```text
process_count=401
total_rss_mb=6858.0
```

Observed after another settle check:

```text
process_count=412
total_rss_mb=7017.9
```

## Rollback

```bash
launchctl enable gui/502/com.apple.chronod
launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.chronod.plist
```

Or reboot after enabling.

## Notes

Logs after bootout mostly showed normal termination and runningboard cleanup of widget extensions.

After reboot there is a short startup burst where clients try to resolve Chrono Mach services and get `No such process`:

```text
ControlCenter -> com.apple.chronoservices
ControlCenter -> com.apple.chrono.controlcenter
NotificationCenter -> com.apple.chronoservices
replicatord -> com.apple.chronod.replicator
calaccessd -> com.apple.chronoservices
```

After the system settled, a 1 minute log check showed no continuing Chrono errors. Current assessment: startup noise, not a tight retry loop.
