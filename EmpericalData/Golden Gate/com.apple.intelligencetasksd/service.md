# Intelligence Tasks Engine — `com.apple.intelligencetasksd`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Apple Intelligence Tasks Engine & Maintenance                 |
| Category      | `apple_intelligence`                                           |
| Risk Level    | **2** — Disables background intelligence batch maintenance    |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable**                                                   |

- **Main label:** `gui/<uid>/com.apple.intelligencetasksd`
- **Plist:** `/System/Library/LaunchAgents/com.apple.intelligencetasksd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/IntelligenceTasksEngine.framework/Support/intelligencetasksd`
- **Domain:** `gui/<uid>`
- **Mach Services:** `com.apple.intelligencetasksd.sets.Maintenance`
- **Background Tasks:** Maintenance A/B/C, Spotlight nightly verification, Spotlight post-install verification.

## What It Does (За что отвечает)

`intelligencetasksd` handles background task scheduling, model sets maintenance, and verification routines for Apple Intelligence in **macOS Golden Gate 27**.

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.intelligencetasksd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.intelligencetasksd"
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.intelligencetasksd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.intelligencetasksd.plist
```
