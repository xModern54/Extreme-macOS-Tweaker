# com.apple.contactsd

## Purpose

Contacts / AddressBook per-user stack.

Main observed process:

```text
/System/Library/Frameworks/Contacts.framework/Support/contactsd
```

Main launchd job:

```text
gui/502/com.apple.contactsd
/System/Library/LaunchAgents/com.apple.contactsd.plist
```

Related Contacts jobs disabled with it:

```text
com.apple.AddressBook.SourceSync
com.apple.AddressBook.abd
com.apple.AddressBook.AssistantService
com.apple.contacts.postersyncd
com.apple.contacts.donation-agent
```

## Why Disable

The target coding-only profile does not use the local Contacts app, iCloud contacts, contact posters, AddressBook source sync, or contacts-based suggestions.

`contactsd` also produced a known side effect after Spotlight was disabled: it periodically tried to reach CoreSpotlight via `com.apple.spotlight.IndexAgent`.

Observed before disable:

```text
contactsd: ~31 MB RSS after fresh boot
previously observed up to ~78 MB RSS
```

## Applied

```bash
launchctl disable gui/502/com.apple.contactsd
launchctl disable gui/502/com.apple.AddressBook.SourceSync
launchctl disable gui/502/com.apple.AddressBook.abd
launchctl disable gui/502/com.apple.AddressBook.AssistantService
launchctl disable gui/502/com.apple.contacts.postersyncd
launchctl disable gui/502/com.apple.contacts.donation-agent
```

`contactsd` did not bootout cleanly from its on-demand state, so the already-running process was terminated after disabling:

```bash
kill -TERM <contactsd-pid>
```

## Result

```text
com.apple.contactsd => disabled
com.apple.AddressBook.SourceSync => disabled
com.apple.AddressBook.abd => disabled
com.apple.AddressBook.AssistantService => disabled
com.apple.contacts.postersyncd => disabled
com.apple.contacts.donation-agent => disabled
No Contacts / AddressBook processes in the checked filter.
```

Immediate log check after stop showed normal `runningboardd` XPC invalidation only, no obvious retry loop.

## Not Touched Yet

These are related but broader than Contacts and were not disabled in this step:

```text
com.apple.dataaccess.dataaccessd
com.apple.accountsd
com.apple.familycircled
com.apple.UserPictureSyncAgent
```

## Risk

Risk level: 2.

Expected breakage:

```text
Contacts.app backend
local contact database services
iCloud/CardDAV contact sync
AddressBook APIs for apps that request contacts
contact posters
contacts donation/suggestions
some contact pickers or autofill features
```

Not expected to break:

```text
boot
login
SSH
normal coding workflow
basic networking
```

Reboot validation on 2026-06-20:

```text
Contacts / AddressBook processes did not return after reboot.
SSH, sudo, default route, Finder, Dock, ControlCenter, and NotificationCenter remained alive.
```

Observed shortly after reboot:

```text
process_count=388
total_rss_mb=6303.8
```

Observed after ~2 minutes uptime:

```text
process_count=393
total_rss_mb=6554.1
```

However, log validation found a real retry pattern from clients that expect Contacts persistence services:

```text
calaccessd -> com.apple.contactsd.persistence
sharingd -> com.apple.contactsd.persistence
peopled -> com.apple.contactsd.persistence
dataaccessd -> com.apple.contactsd.persistence
sharingd/peopled/dataaccessd -> com.apple.AddressBook.ContactsAccountsService
```

Settled 1 minute log sample:

```text
120 matching lines
57 sharingd
28 launchd
11 peopled
11 dataaccessd
```

Current assessment: `contactsd` can be disabled, but it should probably be paired with disabling dependent Apple ecosystem clients such as `sharingd`, `peopled`, and possibly DataAccess/Calendar components, otherwise log spam remains.

Follow-up on 2026-06-20:

Disabled dependent clients:

```bash
launchctl bootout gui/502/com.apple.calaccessd
launchctl disable gui/502/com.apple.calaccessd

launchctl bootout gui/502/com.apple.peopled
launchctl disable gui/502/com.apple.peopled

launchctl bootout gui/502/com.apple.familycircled
launchctl disable gui/502/com.apple.familycircled
```

Observed before disable:

```text
calaccessd: ~29 MB RSS
peopled: ~20 MB RSS
familycircled: ~14 MB RSS
```

Observed after disable:

```text
No calaccessd process.
No peopled process.
No familycircled process.
```

Settled 1 minute contact retry log sample after disabling these dependent clients:

```text
0 matching contact retry lines
```

Remaining related processes:

```text
sharingd
dataaccessd
```

Follow-up reboot validation showed one more important issue: `contactsd` can also launch in non-GUI `user/<uid>` domains for system service users, not only in `gui/502`.

Observed after reboot:

```text
user/247/com.apple.contactsd  _gamecontrollerd
user/260/com.apple.contactsd  _applepay
user/274/com.apple.contactsd  _installcoordinationd
user/277/com.apple.contactsd  _rmd
user/278/com.apple.contactsd  _accessoryupdater
user/501/com.apple.contactsd  xmodern
```

Fix applied:

```bash
sudo launchctl disable user/247/com.apple.contactsd
sudo launchctl disable user/260/com.apple.contactsd
sudo launchctl disable user/274/com.apple.contactsd
sudo launchctl disable user/277/com.apple.contactsd
sudo launchctl disable user/278/com.apple.contactsd
sudo launchctl disable user/501/com.apple.contactsd
```

Already-running `contactsd` processes in these domains were terminated after disabling.

Result after corrected user-domain disable:

```text
No contactsd processes.
Settled 1 minute contact retry sample: 0 matching retry lines.
```

Current assessment after follow-up: the Contacts bundle must disable `contactsd` in the active GUI user domain and in any observed `user/<uid>` domains where it has launched. Disabling `calaccessd`, `peopled`, and `familycircled` reduces dependent Contacts clients.

2026-06-20 follow-up after `sharingd` reboot validation:

```text
sharingd remained disabled and was no longer the contact retry source.
Current remaining contact retry source: dataaccessd.
```

Settled 1 minute sample after reboot:

```text
19 matching lines
11 dataaccessd
5 launchd
2 tccd
```

Next likely dependent candidate for this bundle:

```text
com.apple.dataaccess.dataaccessd
```

## Rollback

```bash
launchctl enable gui/502/com.apple.contactsd
launchctl enable gui/502/com.apple.AddressBook.SourceSync
launchctl enable gui/502/com.apple.AddressBook.abd
launchctl enable gui/502/com.apple.AddressBook.AssistantService
launchctl enable gui/502/com.apple.contacts.postersyncd
launchctl enable gui/502/com.apple.contacts.donation-agent

launchctl bootstrap gui/502 /System/Library/LaunchAgents/com.apple.contactsd.plist
```

Or reboot after enabling.

## Regression fix (2026-07-20) — `user/<uid>` domain

### Root cause

After later reboots on target user `codex` **uid 502**, `contactsd` was alive again (~20 MB) even though AddressBook satellites stayed disabled.

Discovery:

```text
process: contactsd pid running
domain:  user/502/com.apple.contactsd     ← actual job
gui/502/com.apple.contactsd             ← NOT loaded / not the runner
system print-disabled had contactsd     ← useless for this LaunchAgent
user/502 print-disabled: NO contactsd   ← missing override
gui/502 print-disabled: NO contactsd    ← missing override (only postersync/donation/AB helpers)
```

`contactsd` starts on **mach IPC** into the **`user/<uid>`** domain (not only `gui/<uid>`).  
Earlier fix disabled other `user/*` uids and assumed `gui/502`; on this session the live domain was **`user/502`**, and the `contactsd` disable bits for gui+user were gone (reinstall / bulk list gap / override drift).

Siblings still disabled and fine:

```text
AddressBook.SourceSync, AddressBook.abd, AddressBook.AssistantService
contacts.postersyncd, contacts.donation-agent, peopled
```

### Fix applied

```bash
uid=$(id -u)
for domain in "user/$uid" "gui/$uid"; do
  launchctl bootout "$domain/com.apple.contactsd" 2>/dev/null || true
  launchctl disable "$domain/com.apple.contactsd"
done
```

### Validation

| Step | Result |
|------|--------|
| Bootout user/502 | process gone immediately |
| disable user/502 + gui/502 | both show `contactsd => disabled` |
| Health post-bootout | PASS; gone; no process retry |
| Reboot | SSH OK; contactsd **does not return** |
| user+gui still disabled | PASS |
| Log | Boot-time **ControlCenter** lookups to `contactsd.persistence` (~10–15 s), then **quiet** (0 hits in later 60 s sample). Not a spawn loop. |

**Verdict: keep disabled.** Must always disable **both** `user/$uid` and `gui/$uid` for `com.apple.contactsd`. Tweaker must not hard-code only `gui/`.

### Tweaker rule

```text
contactsd:
  domains: [user/{{uid}}, gui/{{uid}}]
  also: AddressBook.* helpers, postersyncd, donation-agent
  dependents already handled: peopled, calaccessd, familycircled, sharingd (separate cards)
```
