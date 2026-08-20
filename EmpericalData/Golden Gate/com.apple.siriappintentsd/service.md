# Siri App Intents Runtime Daemon — `com.apple.siriappintentsd`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Siri App Intents Orchestrator (macOS 27 Golden Gate)          |
| Category      | `siri_intelligence`                                           |
| Risk Level    | **2** — Disables Siri App Intents orchestrator                |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable**                                                   |

- **Main label:** `gui/<uid>/com.apple.siriappintentsd`
- **Plist:** `/System/Library/LaunchAgents/com.apple.siriappintentsd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/SiriAppIntentsRuntime.framework/siriappintentsd`
- **Domain:** `gui/<uid>`
- **Mach Services:** `com.apple.private.siriappintentsd.orchestrator`

## What It Does (За что отвечает)

`com.apple.siriappintentsd` is the background Siri App Intents runtime engine introduced in **macOS Golden Gate 27**.

1. **App Intent Orchestration:** Resolves and dispatches App Intents queries invoked by Siri and Siri AI.
2. **Intent Registry:** Communicates with AppIntents frameworks and Application Services.

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.siriappintentsd" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.siriappintentsd"
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.siriappintentsd"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.siriappintentsd.plist
```
