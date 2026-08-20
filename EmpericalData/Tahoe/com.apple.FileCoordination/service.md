# File Coordination & Atomic Access Protocol Server — filecoordinationd

## Basics

- **Main label:** `system/com.apple.FileCoordination`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.FileCoordination.plist`
- **Binary:** `/usr/sbin/filecoordinationd`
- **Domain:** `system`
- **Category:** `core_macos_file_system`
- **Risk:** `4` (Critical System Infrastructure & File Integrity Safety)
- **Verdict:** `PROTECTED — DO NOT DISABLE`

## What It Does

`filecoordinationd` (File Coordination Daemon) is Apple's primary file access coordination and atomic I/O protocol daemon (`NSFileCoordinator` / `NSFilePresenter` / Foundation Framework):

1. **Atomic File Access & Conflict Prevention (`NSFileCoordinator`)**: Coordinates concurrent file read/write access between applications (VSCode, Xcode, Git, Finder, build scripts), preventing race conditions and file corruption during simultaneous edits.
2. **Editor Live File Update Presenter (`NSFilePresenter`)**: Notifies open code editors when files are modified externally (e.g. `git checkout` or automated build steps), enabling instant tab reloading without data loss.
3. **Kernel IPC Special Port (`HostSpecialPort: 30`)**: Binds to XNU kernel special port 30 (`com.apple.FileCoordination.kernel.ipc`) for system-wide I/O progress tracking (`com.apple.ProgressReporting`).

## Why It Must Remain Enabled

- Disabling `filecoordinationd` **corrupts project source files and breaks IDE file tracking across macOS**: Code editors (VSCode, Xcode), Git, and scripts lose atomic file locking, resulting in data corruption during builds and broken live file updates.
- Explicitly protected in `AGENTS.md` core file system guidelines.

## Status

**KEPT ENABLED AND PROTECTED.**
