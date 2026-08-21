# com.apple.MenuBarAgent

## Basics

- **Process names:** `MenuBarAgent`
- **Domain:** `gui/<uid>`
- **Plist:** `/System/Library/LaunchAgents/com.apple.MenuBarAgent.plist`
- **Binary:** `/System/Library/CoreServices/MenuBarAgent.app/Contents/MacOS/MenuBarAgent`
- **Category:** `system_ui_menu_bar`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Core graphical scene coordinator for the macOS Menu Bar and Status Bar (`FrontBoard` / `SkyLight` / `AppKit`).
Manages and renders:
1. Top application menu bar (Apple logo, File, Edit, View, Window, Help).
2. Status items / Menu Extras (`com.apple.appkit.status-items`).
3. Control Center item integration and system banners (`com.apple.MenuBarAgent.control-center-items`).
4. Global menu bar keyboard shortcuts and menu dropdown event tracking.

Why we looked at it:
Investigated during GUI components scan on macOS 27 Golden Gate.

Resource footprint:
~33.5 MB RAM, 0.0% CPU idle.

Needed for coding / system:
Yes. Critical core desktop UI component. Disabling it destroys the top menu bar across all macOS applications.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4)**.
Essential macOS desktop interface component.
