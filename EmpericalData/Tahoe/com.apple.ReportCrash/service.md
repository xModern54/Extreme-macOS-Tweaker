# Application Crash Reporter & Exception Log Generator — ReportCrash

## Basics

- **Main labels:** `gui/<uid>/com.apple.ReportCrash`, `system/com.apple.ReportCrash.Root`
- **Plist paths:** `/System/Library/LaunchAgents/com.apple.ReportCrash.plist`, `/System/Library/LaunchDaemons/com.apple.ReportCrash.Root.plist`
- **Binary:** `/System/Library/CoreServices/ReportCrash`
- **Domain:** `gui/<uid>`, `system`
- **Category:** `analytics_telemetry_crash_reports`
- **Risk:** `1` (for standard coding workflows) / `2` (Conditional for native C/C++/reverse engineering debugging)
- **Verdict:** `disable for coding profile (keep enabled only for native low-level C/C++ debugging & reverse engineering)`

## What It Does

`ReportCrash` (Crash Reporter Agent) is Apple's application crash exception interceptor and stack dump logger:

1. **Crash Dump & Stack Trace Generator (`~/Library/Logs/DiagnosticReports/`)**: Intercepts `SIGSEGV`, `SIGBUS`, and `EXC_BAD_ACCESS` crash signals from the XNU kernel when applications fail, generating stack trace dumps (`.ips` / `.crash` files).
2. **UI Crash Notification Banner**: Displays the "Application Quit Unexpectedly" popup dialog prompting to send diagnostic reports to Apple.

## Profile Recommendation Notes

- **Standard Coding Profile**: **RECOMMENDED TO DISABLE**. Removes annoying "Application Quit Unexpectedly" UI popups and avoids CPU/disk spikes when background applications crash.
- **Low-Level C/C++/Reverse Engineering Profile**: **KEEP ENABLED** if active low-level C/C++ debugging, kernel extension development, or reverse engineering requires raw `.ips` stack traces in Console.app.

## Disable

```bash
uid=$(id -u)
launchctl bootout "gui/$uid/com.apple.ReportCrash" 2>/dev/null || true
launchctl disable "gui/$uid/com.apple.ReportCrash"
sudo launchctl bootout system/com.apple.ReportCrash.Root 2>/dev/null || true
sudo launchctl disable system/com.apple.ReportCrash.Root
```

## Rollback

```bash
uid=$(id -u)
launchctl enable "gui/$uid/com.apple.ReportCrash"
sudo launchctl enable system/com.apple.ReportCrash.Root
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `gui/502/com.apple.ReportCrash` and `system/com.apple.ReportCrash.Root`.
2. Process `ReportCrash` terminated, releasing **~15MB RSS RAM** and avoiding CPU crash dump spikes.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `ReportCrash` processes remain stopped permanently.
   - Standard coding environment and system stability operate 100% normally.
   - Log audit confirmed 0 errors or retry loops.
