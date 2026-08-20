# Document Versions / revisiond

## Basics

- **Label:** `com.apple.revisiond`
- **Process:** `revisiond`
- **Domain:** `system`
- **Binary:** `/System/Library/PrivateFrameworks/GenerationalStorage.framework/Versions/A/Support/revisiond`
- **Category:** `document_versions`
- **Risk:** `2`
- **Verdict:** `disable for coding profile`

## What It Does

Storage manager for macOS document revisions / Versions / Auto Save history.

This is the backend for features like:

```text
File -> Revert To -> Browse All Versions
```

For this coding-focused setup, the feature is likely not important because code is versioned through Git and editors/IDEs have their own history.

## Expected Impact If Disabled

Likely affected:

```text
Document version history
Auto Save revision storage
Revert To / Browse All Versions
```

Not expected to affect:

```text
boot
login
networking
SSH
Git
normal file open/save
```

## Current Cost

Observed on 2026-06-19:

```text
revisiond  9.9 MB
```

## Candidate Disable

```bash
sudo launchctl disable system/com.apple.revisiond
sudo launchctl bootout system/com.apple.revisiond 2>/dev/null || true
```

## Rollback

```bash
sudo launchctl enable system/com.apple.revisiond
```

Reboot after rollback.

## Test Result

2026-06-19 temporary bootout test succeeded.

Before:

```text
revisiond  9.9 MB
```

Command:

```bash
sudo launchctl bootout system/com.apple.revisiond
```

After:

```text
AFTER_REVISIOND_RSS: 0 processes, 0.0 MB
```

It did not restart after 5 seconds. `launchctl print system/com.apple.revisiond` reported service not found after bootout.

2026-06-19 persistent disable reboot test succeeded.

Command:

```bash
sudo launchctl disable system/com.apple.revisiond
sudo launchctl bootout system/com.apple.revisiond 2>/dev/null || true
```

After reboot at 12 seconds uptime:

```text
REVISIOND_RSS: 0 processes, 0.0 MB
com.apple.revisiond => disabled
```

Console login, passwordless sudo, and default route still worked.
