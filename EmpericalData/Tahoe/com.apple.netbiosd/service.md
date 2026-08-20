# NetBIOS Name Service (netbiosd) — Disabled

## Basics

| Field         | Value                                                        |
|---------------|--------------------------------------------------------------|
| Feature group | Legacy NetBIOS / SMB local name resolution                   |
| Category      | `networking`                                                 |
| Risk Level    | 1 — breaks legacy SMB browsing only; SSH/dev unaffected      |
| Status        | **Disabled** on target — headless PASS (2026-06-29)          |

## What It Does

`netbiosd` provides **NetBIOS name service** for legacy SMB/Windows-style file sharing on the local network:

- Listens on **UDP 137** (`netbios-ns`) and **UDP 138** (`netbios-dgm`)
- Resolves NetBIOS host names for SMB browsing (`smb://` neighbors, old Windows shares)
- Runs as unprivileged user `_netbios` with `Nice = 20` and `LowPriorityIO`
- Kept alive when a **default route** exists (`com.apple.reachability` event)

Modern macOS file access over SMB can work without NetBIOS in many cases; this daemon is mainly for **legacy LAN name discovery**.

On the target: **no `smbd`**, File Sharing off, but `netbiosd` still consumed ~8.5 MB RSS.

## Observed Cost (before disable)

| Metric | Value |
|--------|-------|
| RSS | ~8.5 MB |
| CPU | 0% idle |
| Network | UDP 137/138 bound on `0.0.0.0` when running |
| Logs | Boot race log `Address already in use` on 137/138 (launchd socket handoff), then quiet |

## Launchd Labels

| Label | Domain | Plist | Binary |
|-------|--------|-------|--------|
| `com.apple.netbiosd` | system | `/System/Library/LaunchDaemons/com.apple.netbiosd.plist` | `/usr/sbin/netbiosd` |

**Related (not disabled):** `com.apple.smbd` — SMB file server (not running on target).

## Disable

```bash
sudo launchctl bootout system/com.apple.netbiosd 2>/dev/null || true
sudo launchctl disable system/com.apple.netbiosd
```

## Rollback

```bash
sudo launchctl enable system/com.apple.netbiosd
sudo shutdown -r now
```

## Test Result

**2026-06-29 — netbiosd-off**

| Check | Result |
|-------|--------|
| Immediate process exit | PASS |
| UDP 137/138 released | PASS |
| `launchctl print-disabled` | PASS — `com.apple.netbiosd` => disabled |
| Reboot persistence | PASS — process did not return, ports not bound |
| SSH | PASS |
| Wi‑Fi / default route / DNS (en0) | PASS |
| Unified logs (`netbios`) | PASS — quiet since boot |

**Savings:** ~8.5 MB RSS; no NetBIOS UDP listeners on LAN.

**GUI:** not yet confirmed by user.

## Expected Breakage

- Legacy SMB **network browsing** via NetBIOS names may fail
- Some old Windows clients discovering this Mac by NetBIOS name may fail
- Direct `smb://host` by IP or modern Bonjour/mDNS names should still work if SMB server were enabled

Should **not** affect: SSH, Git, DNS, Wi‑Fi, general internet, AFP-less modern workflows.

## Notes

- Safe trim for coding-only machines not sharing files to Windows over LAN.
- Future tweaker question: *Do you use SMB/Windows file sharing or NetBIOS browsing on the local network?*