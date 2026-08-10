# Extreme Mac Tweaker

Extreme Mac Tweaker is a macOS system optimization and customization utility designed to give advanced users deep control over their macOS installation.

## Key Features

1. **Smart launchd Service Management (Mass Toggling)**
   - Allows users to disable specific system functions they do not use (e.g., Spotlight).
   - Automatically resolves dependencies and disables all related background `launchd` services/daemons.

2. **System Apps & Components Removal**
   - Enables deletion of default system applications and components.
   - Achieved by remounting the macOS Signed System Volume (SSV) / system snapshot using privileged capabilities and low-level tools (UBLS/APFS snapshots).
   - Requires disabling **System Integrity Protection (SIP)** and **Authenticated Root**.
   - Prompts the user with explicit notifications/warnings about security changes and requires privilege escalation via a privileged helper tool (asking for the root password).

3. **Security & Protection Systems Toggling**
   - A dedicated tab/section to disable system protection mechanisms, such as XProtect services, Gatekeeper, and related security daemons.

## Project Architecture & Requirements

- **Platform:** macOS
- **Privilege Level:** Requires root privileges (handled via a Privileged Helper Tool / helper daemon).
- **Prerequisites:** Users must be informed about disabling SIP (System Integrity Protection) and Authenticated Root prior to modifying the system volume.
- **UI Structure:** Tabs/Views corresponding to each of the three major functional areas.

## Privileged Execution Architecture

- `Tweaker.app` always runs as the logged-in user and owns pending changes, plan compilation, ordering, progress, and error presentation.
- `RootTweakAction` is a separate ARM64 command-line target embedded at `Tweaker.app/Contents/Resources/Helpers/RootTweakAction`.
- The GUI creates one Authorization Services session per Apply operation and reuses it for sequential one-shot root helper invocations.
- The macOS App Sandbox is disabled because Authorization Services privilege escalation is not available inside it.
- Each helper process performs exactly one primitive action, streams JSON Lines events to stdout, returns one final completed/failed event, and exits.
- Shared event/result models live in `PrivilegedProtocol/` and compile into both targets.
- System-app plans are ordered as preflight, mount base System volume, perform all app moves/deletions, create a bootable snapshot with `bless`, and unmount.
- The default writable mount point is `/Volumes/SystemRW`; the helper discovers the base APFS System volume dynamically from `diskutil info -plist /`.
- Current helper commands are `identity`, `preflight`, `mount-system-volume`, `unmount-system-volume`, `disable-application`, `restore-application`, `delete-application`, and `create-snapshot`.

## Development Workflow

- The application UI and all user-facing text must be written in English. Localization may be added later.
- The Xcode project uses a file-system-synchronized root group. New source files and resources placed inside `ExtremeMacTweaker/` are discovered by Xcode and automatically included in the application target. Do not manually add ordinary files to `project.pbxproj`.
- Run `./Build.sh` after every code change. It always creates an ARM64-only Release build in `.build/DerivedData`, builds both targets, embeds `RootTweakAction`, and verifies its ARM64 architecture. A successful build prints only `complete`; a failed build prints the complete Xcode log.
- After a successful build at the end of every implementation task, run `./Deploy.sh "descriptive commit message"`.
- `Deploy.sh` terminates the previous ExtremeMacTweaker process, launches the newly built application, stages all repository changes, creates a commit with the supplied message, and pushes the current branch to `origin`.
- Never run `Deploy.sh` before `Build.sh` succeeds.

## Repository

- Remote: `https://github.com/xModern54/Extreme-macOS-Tweaker.git`
- Primary branch: `main`
