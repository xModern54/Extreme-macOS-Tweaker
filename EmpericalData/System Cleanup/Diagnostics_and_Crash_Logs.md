# Diagnostic Reports, ASL, & Crash Logs

## Target Directories

- `/Library/Logs/DiagnosticReports`
- `~/Library/Logs/DiagnosticReports`
- `~/Library/Logs`
- `/private/var/log` (excluding system-required daemon sockets)
- `/private/var/log/asl`
- `/private/var/log/DiagnosticMessages`

## Footprint

- **Typical Size:** `200 MB – 3.0+ GB`
- **Observed on Physical Mac:** `~60 MB` (clean install), grows to gigabytes on older systems or after repeated crashes.

## What Is Stored Here

- Process crash stacks (`.ips`, `.crash`, `.diag`).
- Kernel panic logs and hardware diagnostics.
- Apple System Log (ASL) legacy binary trace databases.
- Unified Logging disk buffers and legacy syslogs.

## Related Daemons & Agents

- `com.apple.ReportCrash`
- `com.apple.ReportCrash.Root`
- `com.apple.aslmanager`
- `com.apple.syslogd`
- `com.apple.spindump`
- `com.apple.tailspind`

## Safety & Verdict

- **Safety Level:** **100% Safe to Delete**
- **Verdict:** `purge`
- **Behavior After Removal:**
  - Zero functional impact on running applications.
  - Frees inode count and disk space.
  - New crash logs are created only if a new crash event occurs.
