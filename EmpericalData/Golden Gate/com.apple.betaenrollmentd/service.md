# com.apple.betaenrollmentd / com.apple.betaenrollmentagent

## Basics

- **Process names:** `betaenrollmentd`, `betaenrollmentagent`
- **Domain:** `system` (`com.apple.betaenrollmentd`), `gui/<uid>` (`com.apple.betaenrollmentagent`)
- **Plist:** 
  - `/System/Library/LaunchDaemons/com.apple.betaenrollmentd.plist`
  - `/System/Library/LaunchAgents/com.apple.betaenrollmentagent.plist`
- **Binary:** `/usr/libexec/betaenrollmentd`, `/usr/libexec/betaenrollmentagent`
- **Category:** `system_update_beta_program_enrollment`
- **Risk:** `0`
- **Verdict:** `disable`

## Notes

What it does:
Apple Beta Software Program (Seed Enrollment) Daemon & Agent (`betaenrollmentd`).
Responsible for:
1. **Apple Beta Seed Verification**: Manages Apple ID enrollment in Developer Beta and Public Beta channels.
2. **Beta Catalog Token Synchronization**: Contacts Apple seed servers (`seedmanifest`) to fetch beta build catalog configurations.

Why we looked at it:
Part of background update and enrollment audit on macOS 27 Golden Gate.

Resource footprint:
~5–7 MB RAM when active, 0.0% CPU.

Needed for coding / system:
No. Standard release macOS updates and App Store downloads work 100% normally. Required only if you actively want to download macOS Beta seed updates via System Settings.

Disable:
```bash
sudo launchctl disable system/com.apple.betaenrollmentd
launchctl disable gui/<uid>/com.apple.betaenrollmentagent
```

Test result:
Tested on macOS 27 Golden Gate. Safely disabled and rebooted cleanly.
Verdict: **SAFE TO DISABLE (Risk 0)**.
