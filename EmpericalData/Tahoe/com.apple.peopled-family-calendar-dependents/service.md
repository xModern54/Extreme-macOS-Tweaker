# Contacts Dependent Clients

## Scope

Dependent clients disabled after `com.apple.contactsd` because they continued to query dead Contacts / AddressBook Mach services.

Jobs:

```text
com.apple.calaccessd
com.apple.peopled
com.apple.familycircled
```

## Purpose

```text
calaccessd     Calendar/EventKit daemon, calendar database, alerts, travel/location calendar features.
peopled        People framework agent, people suggestions, Find My / Screen Time / Messages related people signals.
familycircled  Apple Family Sharing / Ask To Buy / family CloudKit and Screen Time related family state.
```

## Why Disable

The target coding-only profile does not use Apple Calendar, Apple Contacts, Family Sharing, Ask To Buy, Screen Time family features, Find My people features, or people suggestions.

After disabling Contacts, these clients generated Contacts persistence retry logs.

## Applied

```bash
launchctl bootout gui/502/com.apple.calaccessd
launchctl disable gui/502/com.apple.calaccessd

launchctl bootout gui/502/com.apple.peopled
launchctl disable gui/502/com.apple.peopled

launchctl bootout gui/502/com.apple.familycircled
launchctl disable gui/502/com.apple.familycircled
```

## Result

Before disable:

```text
calaccessd: ~29 MB RSS
peopled: ~20 MB RSS
familycircled: ~14 MB RSS
```

After disable:

```text
No calaccessd process.
No peopled process.
No familycircled process.
```

Log check:

```text
Before: contact retry pattern from calaccessd, peopled, dataaccessd, sharingd.
After: settled 1 minute contact retry sample showed 0 matching retry lines.
```

## Risk

Risk level: 2.

Expected breakage:

```text
Calendar.app backend and alerts
Calendar/EventKit sync helpers
People suggestions
Find My people signals
Apple Family Sharing
Ask To Buy
family Screen Time features
some Apple ecosystem contact/people UI
```

Not expected to break:

```text
boot
login
SSH
normal coding workflow
basic networking
```

Needs reboot validation as part of the broader Contacts / People bundle.

## Rollback

```bash
launchctl enable gui/502/com.apple.calaccessd
launchctl enable gui/502/com.apple.peopled
launchctl enable gui/502/com.apple.familycircled

launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.calaccessd.plist
launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.peopled.plist
launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.familycircled.plist
```

Or reboot after enabling.
