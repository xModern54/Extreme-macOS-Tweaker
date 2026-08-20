# CoreAnalytics Hub — `com.apple.analyticsd` (macOS 27 Golden Gate Behavior)

## Basics

| Field         | Value                                                         |
|---------------|---------------------------------------------------------------|
| Feature group | Apple Analytics Hub & Telemetry Ingest                        |
| Category      | `privacy_diagnostics` / `analytics_telemetry`                |
| Risk Level    | **2** — Central telemetry ingest daemon                       |
| Profile       | **safe to bootout on coding target**                          |
| Verdict       | **force-enabled by IOKit matching at boot in macOS 27**       |

- **Main label:** `system/com.apple.analyticsd`
- **Plist:** `/System/Library/LaunchDaemons/com.apple.analyticsd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/CoreAnalytics.framework/Support/analyticsd`
- **Domain:** `system`
- **User:** `_analyticsd`
- **Observed RSS:** **~23.7 MB**
- **Properties in macOS 27:** `force-enabled | supports transactions | supports pressured exit`
- **Trigger:** `IOProviderClass = CoreAnalyticsMessenger` (`keepalive = 1`, stream `com.apple.iokit.matching`)

## Why It Auto-Started After Reboot

In **macOS 27 Golden Gate**, `launchctl disable system/com.apple.analyticsd` alone is bypassed during cold system startup because:
1. Kernel IOKit driver matching initializes `CoreAnalyticsMessenger`.
2. Launchd evaluates the matching event stream with `keepalive = 1` and Mach IPC lookup, tagging the job as `force-enabled`.
3. This wakes up `analyticsd` on initial boot even when present in `print-disabled`.

## How To Terminate

Executing a direct system bootout removes the Mach port listener and terminates the daemon cleanly for the remainder of the session:

```bash
sudo launchctl bootout system/com.apple.analyticsd 2>/dev/null || true
```

After bootout:
- Memory released: **~24 MB RAM**.
- `analyticsd` remains completely stopped until the next cold reboot.
- `logd`, crash reporting (`ReportCrash`), and core system stability remain 100% unaffected.
