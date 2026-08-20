# Siri AI Application & UI Host — `com.apple.campo`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Siri & Apple Intelligence (macOS 27 Golden Gate New Stack)   |
| Category      | `siri_intelligence` / `apple_intelligence`                   |
| Risk Level    | **2** — Disables new Siri AI application and background agent  |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable** (frees ~119 MB RAM)                              |

- **Main label:** `gui/<uid>/com.apple.campo`
- **Plist:** `/System/Library/LaunchAgents/com.apple.campo.plist`
- **Binary:** `/System/Applications/Siri AI.app/Contents/MacOS/Siri AI`
- **Helper XPC:** `/System/Library/PrivateFrameworks/CampoUIServices.framework/Versions/A/XPCServices/CampoRemoteService.xpc/Contents/MacOS/CampoRemoteService`
- **Domain:** `gui/<uid>`
- **Mach Services:** `com.apple.campo`
- **Feature Flag Gate:** `IntelligenceFlow/Campo`
- **Properties:** `RunAtLoad = true`, `KeepAlive = { AfterInitialDemand = true, SuccessfulExit = false }`

## What It Does (За что отвечает)

`com.apple.campo` is the primary new Siri AI UI and background assistant runtime introduced in **macOS Golden Gate 27**.

1. **Siri AI Application Host:** Houses the dedicated `/System/Applications/Siri AI.app` native binary running as an active background GUI application (`ProcessType = App`, `Spawn Role = UI`).
2. **Model Updating & Feedback Triggers:** Listens to XPC activity streams for background Spotlight model sync (`com.apple.spotlight.modelUpdating`, interval 86400s) and machine learning feedback telemetry (`com.apple.spotlight.sendmlfeedback`).
3. **UI Remote Services:** Spawns `CampoRemoteService` (`CampoUIServices.framework`) for floating Siri AI overlays and visual prompt interactions.

Not required for CLI development, SSH, compilers, Finder, Dock, or standard macOS desktop operations.

## Observed Cost (macOS 27 Golden Gate Baseline)

| Process | Domain | RSS RAM | CPU Idle |
|---|---|---|---|
| `Siri AI` (`/System/Applications/Siri AI.app`) | `gui/<uid>` | **~99.0 MB** | 0.0% |
| `CampoRemoteService` (`CampoUIServices.framework`) | XPC (`gui/<uid>`) | **~19.7 MB** | 0.0% |
| **Total** | | **~118.7 MB** | **0.0%** |

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.campo" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.campo"
killall "CampoRemoteService" 2>/dev/null || true
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.campo"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.campo.plist
```

## Test Result

**Date:** 2026-08-20  
**Target:** macOS 27.0 Golden Gate (Build 26A5416b, ARM64)

1. Pre-disable: `Siri AI.app` was actively resident at **99,040 KB RSS**, with child `CampoRemoteService` at **19,712 KB RSS** (total **~118.7 MB RAM**).
2. Executed `launchctl bootout gui/$uid/com.apple.campo` and `launchctl disable`.
3. `Siri AI` process terminated immediately without hanging.
4. Memory immediately recovered (**~119 MB RAM released**).
5. No crash logs or system alert popups generated. Desktop, Dock, Finder, and Terminal remained 100% functional.
