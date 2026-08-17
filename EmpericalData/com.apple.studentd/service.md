# com.apple.studentd

## Purpose

`studentd` is a per-user Apple education/Classroom agent.

Observed job:

```text
gui/502/com.apple.studentd
/System/Library/LaunchAgents/com.apple.macos.studentd.plist
/usr/libexec/studentd
```

Observed launch triggers mention:

```text
com.apple.classroomkit.settings-app-launched
com.apple.classroomkit.studentmigrator.request-studentd-launch
com.apple.progressd.studentClassMembershipChanged
~/Library/studentd/isConnected
```

## Why Disable

The target coding-only profile does not use Classroom, Schoolwork, managed student mode, or education device workflows.

Observed before disable:

```text
studentd: ~32 MB RSS
```

## Applied

```bash
launchctl bootout gui/502/com.apple.studentd
launchctl disable gui/502/com.apple.studentd
```

## Result

```text
com.apple.studentd => disabled
No studentd process.
launchctl print gui/502/com.apple.studentd -> service not found.
```

## Risk

Risk level: 1.

Expected breakage:

```text
Apple Classroom / Schoolwork / student management features
education-managed class membership notifications
studentd notifications
```

Not expected to break:

```text
boot
login
SSH
normal coding workflow
```

## Rollback

```bash
launchctl enable gui/502/com.apple.studentd
launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.macos.studentd.plist
```

Or reboot after enabling.
