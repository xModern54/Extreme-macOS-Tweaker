# Feedback Daemon — AppleSeed / Feedback Assistant

## Basics

| Field         | Value                                                          |
|---------------|----------------------------------------------------------------|
| Feature group | `feedbackd` — centralized feedback collection for Feedback Assistant |
| Category      | `analytics_telemetry`                                          |
| Risk Level    | 1 — not needed for coding workflow                               |

## What It Does

Per-user LaunchAgent for Apple's **Feedback Assistant** / AppleSeed feedback pipeline. Processes feedback notifications on a repeating XPC activity schedule (~6 h interval) and exposes centralized feedback Mach service.

Binary: `/usr/libexec/feedbackd`

Registers `com.apple.usernotifications.delegate.com.apple.appleseed.FeedbackAssistant` — irrelevant after notification stack disable, but daemon still ran independently.

Not required for SSH, compilers, Git, or development tools.

## Observed Cost (before disable)

| Process    | Domain | RSS    |
|------------|--------|--------|
| `feedbackd` | gui   | ~9 MB  |

## Launchd Labels

| Label               | Plist                                                      | Domain |
|---------------------|------------------------------------------------------------|--------|
| `com.apple.feedbackd` | `/System/Library/LaunchAgents/com.apple.feedbackd.plist` | gui    |

### MachServices

```text
com.apple.feedbackd.centralized-feedback
com.apple.usernotifications.delegate.com.apple.appleseed.FeedbackAssistant
```

### LaunchEvents

```text
com.apple.xpc.activity — com.apple.feedbackd.process-notifications (every 21600s)
```

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.feedbackd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.feedbackd"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.feedbackd"
sudo shutdown -r now
```

## Test Result

**Date:** 2026-06-20

1. Pre-disable: `feedbackd` running ~9 MB RSS.
2. Bootout — process disappeared immediately.
3. 30-second delayed check — did not return.
4. Disabled flag confirmed in `launchctl print-disabled`.
5. Reboot — SSH back ~18 seconds.
6. Post-reboot: no `feedbackd` process; disable flag intact.
7. Health: gateway, memory pressure OK.

**Verdict: safe to disable on coding experimental target.**

## Expected Breakage

- Feedback Assistant / AppleSeed centralized feedback submission plumbing.
- No impact on SSH, Wi-Fi, boot, or GUI stability observed.

## Notes

- Small telemetry/feedback slice removed ahead of larger App Store / AMS candidate group.
- Notification delegate endpoint was already non-functional after Group A+B notification disable.