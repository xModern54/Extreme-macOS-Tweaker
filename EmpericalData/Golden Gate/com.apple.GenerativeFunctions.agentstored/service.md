# Agent Session Kit Runtime Daemon — `com.apple.GenerativeFunctions.agentstored`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Apple Intelligence Agentic Sessions & Function Calling        |
| Category      | `apple_intelligence` / `siri_intelligence`                   |
| Risk Level    | **2** — Disables autonomous Agent Session Kit background execution |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable** (frees ~14.3 MB RAM)                              |

- **Main label:** `gui/<uid>/com.apple.GenerativeFunctions.agentstored`
- **Plist:** `/System/Library/LaunchAgents/com.apple.GenerativeFunctions.agentstored.plist`
- **Binary:** `/System/Library/PrivateFrameworks/AgentSessionKitRuntime.framework/Versions/A/agentstored`
- **Domain:** `gui/<uid>`
- **Mach Services:**
  - `com.apple.GenerativeFunctions.agentstored.agentDebug`
  - `com.apple.aps.agentstored`
  - `com.apple.cascade.donationrequest.Siri.Transcript.Turn`
  - `com.apple.generativeexperiences.agentMediaStore`
  - `com.apple.generativeexperiences.agentSessionStore`

## What It Does (За что отвечает)

`agentstored` is Apple's background agent session and function calling manager in **macOS Golden Gate 27**.

1. **Agent Session Persistence:** Manages lifecycle, media stores, and state checkpoints for autonomous AgentSessionKit operations (`com.apple.generativeexperiences.agentSessionStore`, `com.apple.generativeexperiences.agentMediaStore`).
2. **Siri Transcript Donation Bridge:** Receives multi-turn conversation turn donations from Siri and Generative Search (`com.apple.cascade.donationrequest.Siri.Transcript.Turn`).
3. **Scheduled Maintenance:** Executes periodic daily and weekly agent maintenance tasks via `com.apple.bg.system.task`.

Not required for software engineering, terminal tools, or desktop usage.

## Observed Cost (macOS 27 Golden Gate Baseline)

| Process | Domain | RSS RAM | CPU Idle |
|---|---|---|---|
| `agentstored` (`AgentSessionKitRuntime.framework`) | `gui/<uid>` | **~14.3 MB** | 0.0% |

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.GenerativeFunctions.agentstored" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.GenerativeFunctions.agentstored"
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.GenerativeFunctions.agentstored"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.GenerativeFunctions.agentstored.plist
```

## Test Result

**Date:** 2026-08-20  
**Target:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)

1. Pre-disable: `agentstored` was active at **14,288 KB RSS**.
2. Executed `launchctl bootout gui/$uid/com.apple.GenerativeFunctions.agentstored` and `launchctl disable`.
3. Process terminated immediately, saving **~14.3 MB RAM**.
