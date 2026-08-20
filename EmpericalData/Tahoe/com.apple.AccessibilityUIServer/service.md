# Accessibility UI Rendering & Overlay Server — AccessibilityUIServer

## Basics

- **Main label:** `gui/<uid>/com.apple.AccessibilityUIServer`
- **Plist path:** `/System/Library/LaunchAgents/com.apple.AccessibilityUIServer.plist`
- **Binary:** `/System/Library/CoreServices/AccessibilityUIServer.app/Contents/MacOS/AccessibilityUIServer`
- **Domain:** `gui/<uid>`
- **Category:** `accessibility_ui_visuals`
- **Risk:** `1` (for standard coding profiles) / `2` (Conditional for users relying on Screen Zoom overlays)
- **Verdict:** `disable for coding profile`

## What It Does

`AccessibilityUIServer` (Accessibility UI Server) is Apple's primary GUI rendering server for accessibility visual overlays (`AccessibilitySupport.framework`):

1. **Screen Zoom Overlay Renderer (`Cmd+Opt+8`)**: Renders system screen zoom lenses and full-screen magnification overlays.
2. **Mouse Pointer Shake-to-Locate Animator**: Animates temporary mouse pointer enlargement when rapidly shaking the trackpad/mouse.
3. **Accessibility Keyboard & Color Filters**: Renders the on-screen virtual Accessibility Keyboard and display color filter overlays for visually impaired users.

## What Is NOT Affected

- **Normal Mouse, Cursor & Display**: Mouse movement, trackpad gestures, standard cursor size, color accuracy, screen resolution, Terminal, Git, VSCode, Docker, SSH, Wi-Fi, and audio operate **100% normally**.
- **System Memory**: Eliminates persistent GUI app, freeing **~62.7MB RSS RAM**.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.AccessibilityUIServer" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.AccessibilityUIServer"
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.AccessibilityUIServer"
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.AccessibilityUIServer`.
2. Process `AccessibilityUIServer` terminated, releasing **~62.7MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 10 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `AccessibilityUIServer` process remains stopped permanently.
   - Normal mouse cursor, trackpad, display rendering, and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
