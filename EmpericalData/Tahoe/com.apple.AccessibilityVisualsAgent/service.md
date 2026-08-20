# Accessibility UI Focus Ring & Visual Highlight Agent — AccessibilityVisualsAgent

## Basics

- **Main label:** `gui/<uid>/com.apple.AccessibilityVisualsAgent`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.AccessibilityVisualsAgent.plist`
- **Binary:** `/System/Library/PrivateFrameworks/AccessibilitySupport.framework/Versions/A/Resources/AccessibilityVisualsAgent.app/Contents/MacOS/AccessibilityVisualsAgent`
- **Domain:** `gui/<uid>`
- **Category:** `accessibility_ui_visuals`
- **Risk:** `1` (for standard coding profiles)
- **Verdict:** `disable for coding profile`

## What It Does

`AccessibilityVisualsAgent` (Accessibility Visual Highlights Agent) is Apple's GUI agent for accessibility focus indicators and UI highlight overlays (`AccessibilitySupport.framework`):

1. **Focus Ring Renderer (Tab Key Navigation Borders)**: Renders high-contrast blue/white focus ring borders around active UI buttons, text inputs, and control fields during keyboard navigation (`Tab` key focus).
2. **VoiceOver Screen Selection Boxes**: Renders VoiceOver highlight bounding boxes on screen elements.
3. **Cursor Trails & Pointer Highlighting**: Renders visual mouse trails and custom cursor halos.

## What Is NOT Affected

- **Normal Mouse, Cursor & Display**: Mouse movement, trackpad gestures, standard cursor rendering, keyboard inputs, Terminal, Git, VSCode, Docker, SSH, Wi-Fi, and audio operate **100% normally**.
- **System Memory**: Eliminates persistent GUI agent, freeing **~58.8MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.AccessibilityVisualsAgent" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AccessibilityVisualsAgent"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.AccessibilityVisualsAgent"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.AccessibilityVisualsAgent`.
2. Process `AccessibilityVisualsAgent` terminated, releasing **~58.8MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `AccessibilityVisualsAgent` process remains stopped permanently.
   - Active system process count dropped to **155**.
   - Normal mouse cursor, trackpad, display rendering, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
