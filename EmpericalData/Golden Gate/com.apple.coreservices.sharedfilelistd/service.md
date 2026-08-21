# com.apple.coreservices.sharedfilelistd

## Basics

- **Process names:** `sharedfilelistd`
- **Domain:** `gui/<uid>`, `system`
- **Plist:** 
  - `/System/Library/LaunchAgents/com.apple.coreservices.sharedfilelistd.plist`
  - `/System/Library/LaunchDaemons/com.apple.coreservices.sharedfilelistd.plist`
- **Binary:** `/System/Library/CoreServices/sharedfilelistd`
- **Category:** `system_ui_finder_sidebar`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
Finder Sidebar Favorites and Recent Items History Engine (`sharedfilelistd`).
Responsible for:
1. **Finder Sidebar (Боковая панель Finder / Избранное)**: Populates and resolves all sidebar entries (Desktop, Documents, Downloads, Recents, Tags, Locations).
2. **Recent Items ( -> Recent Items)**: Maintains history of recently opened documents, folders, and applications.
3. **Open / Save Dialog Pickers (`Cmd+O` / `Cmd+S`)**: Supplies recent directories and favorite shortcuts to AppKit open/save sheets.

Why we looked at it:
Investigated during Finder and desktop UI component audit.

Why it must NOT be disabled:
Disabling `sharedfilelistd` **completely breaks and wipes the Finder left sidebar** (leaving an empty blank sidebar with no Favorites, Downloads, Documents, or Desktop shortcuts).

Resource footprint:
~10 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Required for normal Finder navigation and system file open/save sheets.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Protected UI Engine)**.
