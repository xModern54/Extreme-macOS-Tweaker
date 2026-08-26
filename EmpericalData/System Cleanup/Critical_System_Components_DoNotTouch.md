# Critical System Components — DO NOT PURGE / TOUCH

## Protected Critical Directories & Files

The following paths must **never** be targeted by bulk cleanup or deletion routines under any circumstances. Wiping any of these files will cause immediate OS instability, login failure, permission corruption, or failure to boot.

---

### 1. `/private/var/db/dslocal/nodes/Default/`
- **What it is:** OpenDirectory user and group database (`.plist` files for each user UID, e.g. `users/xmodern.plist`, `users/root.plist`).
- **Consequence of Deletion:** **Catastrophic.** All user accounts vanish. User cannot log in, `whoami` fails, and system enters broken initial setup loop.

### 2. `/private/var/db/auth.db`
- **What it is:** Authorization Services rights database (rules governing `sudo`, Touch ID, privilege escalation, and root helper authorization).
- **Consequence of Deletion:** Privilege escalation fails completely; users cannot run `sudo` or authenticate root dialogs.

### 3. `/private/var/db/TCC/` & `~/Library/Application Support/com.apple.TCC/TCC.db`
- **What it is:** Transparency, Consent, and Control (TCC) permissions database (Full Disk Access, Accessibility, Screen Recording, Microphone).
- **Consequence of Deletion:** Wipes all privacy grants. All apps will continuously prompt or fail silently on background file accesses.

### 4. `~/Library/Keychains/` & `/Library/Keychains/`
- **What it is:** Apple Keychain secure store containing encrypted user passwords, Wi-Fi keys, SSH certificates, and secure tokens.
- **Consequence of Deletion:** Destroys all stored passwords and credential sessions across macOS and iCloud.

### 5. `/System/Volumes/Data/System/Library/CoreServices/`
- **What it is:** System-link Cryptex mount-points, OS activation tokens, and bootloader stubs.
- **Consequence of Deletion:** May render system unbootable or break Rosetta / security subsystem verification.

### 6. `/private/etc/`
- **What it is:** Core UNIX configuration files (`hosts`, `sudoers`, `pam.d`, `shells`, `fstab`, `ssh/ssh_config`).
- **Consequence of Deletion:** Destroys terminal shell resolution and root PAM authentication.
