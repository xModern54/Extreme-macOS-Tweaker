# Visual Intelligence Daemon — `com.apple.visualintelligenced`

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Apple Visual Intelligence Services (macOS 27 Golden Gate)     |
| Category      | `apple_intelligence` / `media_location`                      |
| Risk Level    | **2** — Disables Visual Intelligence camera & screen analysis |
| Profile       | **safe to disable on coding / power-user target**             |
| Verdict       | **disable**                                                   |

- **Main label:** `gui/<uid>/com.apple.visualintelligenced`
- **Plist:** `/System/Library/LaunchAgents/com.apple.visualintelligenced.plist`
- **Binary:** `/System/Library/PrivateFrameworks/VisualIntelligenceServices.framework/visualintelligenced`
- **Domain:** `gui/<uid>`
- **Mach Services:**
  - `com.apple.visualintelligence.daemon-status`
  - `com.apple.visualintelligence.visual-action-prediction`

## What It Does (За что отвечает)

`visualintelligenced` is the Apple Visual Intelligence runtime introduced in **macOS Golden Gate 27**.

1. **Visual Search & Scene Analysis:** Powers on-device visual recognition, OCR bounding, and action prediction from images and screen captures.
2. **Action Prediction:** Evaluates contextual actions based on visual triggers (`com.apple.visualintelligence.visual-action-prediction`).

## Disable

```bash
uid=$(id -u)

launchctl bootout "gui/$uid/com.apple.visualintelligenced" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.visualintelligenced"
```

## Rollback

```bash
uid=$(id -u)

launchctl enable "gui/$uid/com.apple.visualintelligenced"
launchctl bootstrap "gui/$uid" /System/Library/LaunchAgents/com.apple.visualintelligenced.plist
```
