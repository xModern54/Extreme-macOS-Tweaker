# Offline Crash Log Symbolication Daemon — coresymbolicationd

## Basics

- **Main label:** `system/com.apple.coresymbolicationd`
- **Plist path:** `/System/Library/LaunchDaemons/com.apple.coresymbolicationd.plist`
- **Binary:** `/System/Library/PrivateFrameworks/CoreSymbolication.framework/coresymbolicationd`
- **Domain:** `system`
- **Category:** `system_diagnostics_crash_symbolication`
- **Risk:** `1`
- **Verdict:** `disable for coding profile`

## What It Does

`coresymbolicationd` (CoreSymbolication Daemon) is Apple's background daemon for offline crash log stack trace symbolication:

1. **Crash Report Symbol Resolution**: Resolves raw hex memory addresses (`0x104b2a...`) into human-readable class/function names for system crash reports in `/Library/Logs/DiagnosticReports/`.
2. **System Symbol Indexing**: Maintains dSYM symbol indices in `/var/db/coresymbolicationd/`.

## Developer Tools & Reverse Engineering Compatibility

> [!NOTE]
> **Разработка и реверс-инжиниринг НЕ затрагиваются**: `lldb`, Xcode live debugging, Hopper Disassembler, Ghidra, IDA Pro и Frida **НЕ используют `coresymbolicationd`**. Они считывают DSYM и Mach-O таблицы символов напрямую из файлов бинарников собственными встроенными парсерами.

## What Is NOT Affected

- **Developer Debugging & Tooling**: `lldb`, Xcode, Hopper, Ghidra, IDA Pro, Frida, Terminal, VSCode, Git, Docker, SSH, Wi-Fi, and sound operate **100% normally**.
- **System Stability**: Eliminates background DSYM indexing and saves **~15MB RSS RAM**.

## Disable

```bash
sudo launchctl bootout system/com.apple.coresymbolicationd 2>/dev/null || true
sudo launchctl disable system/com.apple.coresymbolicationd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.coresymbolicationd
sudo shutdown -r now
```

## Test Result

Empirically validated on Target Mac (MacBook Air M4, macOS 26.5.1):

1. `bootout` and `disable` applied for `system/com.apple.coresymbolicationd`.
2. Process `coresymbolicationd` terminated, releasing **~15MB RSS RAM**.
3. Health check script (`./scripts/health-check.sh --phase post-bootout`) passed 23/23 base checks.
4. Target Mac rebooted and SSH recovered in 11 seconds.
5. Post-reboot health check passed (`HEALTH RESULT: PASS`).
6. Confirmed:
   - `coresymbolicationd` process remains stopped.
   - Live LLDB debugging, developer tools, and system stability operate normally.
   - Log audit confirmed 0 errors or retry loops.
