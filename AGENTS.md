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
- System-app plans are ordered as preflight, mount base System volume, perform all app moves/deletions, create a bootable snapshot with `bless`, prune old bootable snapshots, and unmount.
- The default writable mount point is `/Volumes/SystemRW`; the helper discovers the base APFS System volume dynamically from `diskutil info -plist /`.
- Current helper commands are `identity`, `preflight`, `mount-system-volume`, `unmount-system-volume`, `disable-application`, `restore-application`, `delete-application`, `hide-launch-plist`, `restore-launch-plist`, `create-snapshot`, and `prune-system-snapshots`.

## Empirical Data

- `EmpericalData/` holds real launchd-service notes from testing on a physical Mac. Keep it. We may come back to those notes when filling or checking the tweak catalog.
- Do not run ripgrep, `grep`, or other full-tree content search from the project root. That walk hits every `service.md` under `EmpericalData/` and drowns the source results.
- Search `ExtremeMacTweaker/`, `PrivilegedProtocol/`, `RootTweakAction/`, or `Catalog/` instead. Open `EmpericalData/` only when you are looking for those test notes.

## Development Workflow

- The application UI and all user-facing text must be written in English. Localization may be added later.
- The Xcode project uses a file-system-synchronized root group. New source files and resources placed inside `ExtremeMacTweaker/` are discovered by Xcode and automatically included in the application target. Do not manually add ordinary files to `project.pbxproj`.
- Project helper scripts live in `Scripts/`. Do not look for `Build.sh`, `Release.sh`, `Deploy.sh`, or `Catalog.sh` in the repository root.
- Run `./Scripts/Build.sh` after every code change. It always creates an ARM64-only Release build in `.build/DerivedData`, builds both targets with Swift `-O` and C/ObjC `-O3`, embeds `RootTweakAction`, compiles `dqd` at `-O3`, adhoc-signs the app and helpers, verifies ARM64 architecture, and copies the finished `Tweaker.app` to the project root. A successful build prints only `complete`; a failed build prints the complete Xcode log.
- After a successful build at the end of every implementation task, run `./Scripts/Deploy.sh "descriptive commit message"`.
- `Scripts/Release.sh` runs the same Release pipeline as `Build.sh`, then wraps the signed `Tweaker.app` in an adhoc-signed `ExtremeMacTweaker-v<MARKETING_VERSION>-aarch64.dmg` at the project root. Version comes from `CFBundleShortVersionString` in the built app. A successful release prints only `complete`.
- `Scripts/Deploy.sh` terminates the previous ExtremeMacTweaker process, launches the newly built application, stages all repository changes, creates a commit with the supplied message, and pushes the current branch to `origin`.
- Never run `Scripts/Deploy.sh` before `Scripts/Build.sh` succeeds.

## Tweak Catalog Workflow

- System Tweaker data is split by host macOS: `ExtremeMacTweaker/Resources/TweakCatalog.json` for 15–26, `ExtremeMacTweaker/Resources/TweakCatalog.27.json` for 27 and later.
- The loader picks the matching file from the application bundle, or the same filename under `~/Library/Application Support/Tweaker/` if a development override exists.
- Run `./Scripts/Catalog.sh install` once to create both live development overrides. Tweaker reloads successful JSON edits automatically without rebuilding or restarting.
- Run `./Scripts/Catalog.sh sync` to replace both overrides with the repository catalogs and `./Scripts/Catalog.sh path` to print their locations.
- English catalog copy is the fallback. Dynamic localization keys use `tweak.<feature-id>.<field>` and `category.<category-id>.title` from the `TweakCatalog` string table.
- Semantic validation and SHA-256 integrity infrastructure exist in `TweakCatalogValidator` and `TweakCatalogLoader`, but both runtime policies are intentionally disabled during active catalog development.

## Repository

- Remote: `https://github.com/xModern54/Extreme-macOS-Tweaker.git`
- Primary branch: `main`
