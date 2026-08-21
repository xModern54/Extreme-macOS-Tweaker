# com.apple.FileCoordination

## Basics

- **Process names:** `filecoordinationd`
- **Domain:** `system`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.FileCoordination.plist`
- **Binary:** `/usr/sbin/filecoordinationd`
- **Category:** `core_filesystem_coordination_progress`
- **Risk:** `4`
- **Verdict:** `do-not-touch`

## Notes

What it does:
File Coordination & Progress Reporting Daemon (`filecoordinationd`).
Backend implementation for `NSFileCoordinator`, `NSFilePresenter`, and `NSProgress` APIs.
Responsible for:
1. **Concurrent File Access Serialization**: Prevents race conditions and file corruption when multiple applications read and write the same file or directory simultaneously (e.g. Finder moving a file while Xcode or VS Code is saving it).
2. **File Presenter Notifications**: Alerts open editor applications when their open files are modified externally (e.g. by Git, terminal scripts, or compilers) for seamless automatic reload.
3. **System Progress Reporting**: Manages progress bars for file copy, move, and extraction operations in Finder and AppKit sheets (`com.apple.ProgressReporting`).

Why we looked at it:
Found running in process table under root on macOS 27 Golden Gate.

Resource footprint:
~5.7 MB RAM, 0.0% CPU.

Needed for coding / system:
Yes. Critical core framework for filesystem integrity, developer IDEs, Git file synchronization, and Finder copy progress. Disabling it causes file write race conditions, data loss, and UI progress hangs.

Verdict:
**DO NOT TOUCH / KEEP ENABLED (Risk 4 — Filesystem Integrity Component)**.
