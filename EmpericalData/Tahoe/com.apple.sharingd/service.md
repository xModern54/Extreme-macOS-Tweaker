# Sharing / Continuity / Nearby

## Basics

- **Main label:** `com.apple.sharingd`
- **Related labels:** `com.apple.rapportd`, `com.apple.nearbyd`, `com.apple.identityservicesd`, `com.apple.cmio.ContinuityCaptureAgent`, `com.apple.mediacontinuityd`
- **Processes:** `sharingd`, `rapportd`, `nearbyd`, `identityservicesd`, `ContinuityCaptureAgent`, `bluetoothuserd`, `bluetoothd`
- **Domains:** `gui/<uid>`, `system`
- **Category:** `apple_ecosystem_continuity`
- **Risk:** `2-3`
- **Verdict:** `researching`

## What It Does

Apple local sharing and ecosystem features: AirDrop, Share Sheet nearby targets, Handoff, Continuity, device discovery, some IDS/Apple ID messaging channels, nearby interaction, and continuity camera/capture support.

For this coding-only setup, many features are not needed, but this stack overlaps with Bluetooth, IDS, FaceTime/iMessage, and local network discovery.

## Current Cost

Observed on 2026-06-19 under `codexadmin`:

```text
sharingd                69.6 MB
identityservicesd       44.3 MB
bluetoothd              35.8 MB
rapportd                29.1 MB
nearbyd                 16.8 MB
ContinuityCaptureAgent  12.5 MB
bluetoothuserd          12.2 MB

TOTAL_SHARING_STACK_RSS: 7 processes, 220.3 MB
```

The user-provided snapshot from `xmodern` showed `sharingd` at about `58.5 MB`.

## Known Launchd Labels

Core sharing / continuity candidates:

```text
gui/<uid>/com.apple.sharingd
gui/<uid>/com.apple.rapportd
system/com.apple.rapportd
system/com.apple.nearbyd
gui/<uid>/com.apple.cmio.ContinuityCaptureAgent
gui/<uid>/com.apple.mediacontinuityd
gui/<uid>/com.apple.amp.mediasharingd
```

IDS / Apple account messaging layer:

```text
gui/<uid>/com.apple.identityservicesd
gui/<uid>/com.apple.idsfoundation.IDSRemoteURLConnectionAgent
```

Screen sharing / sharing UI:

```text
system/com.apple.screensharing
gui/<uid>/com.apple.screensharing.agent
gui/<uid>/com.apple.screensharing.menuextra
gui/<uid>/com.apple.screensharing.MessagesAgent
```

Bluetooth layer, do not include in first test:

```text
system/com.apple.bluetoothd
gui/<uid>/com.apple.bluetoothuserd
gui/<uid>/com.apple.bluetoothUIServer
gui/<uid>/com.apple.bluetoothaudiod
system/com.apple.BluetoothUIService
```

## Candidate Disable

Stage 1, sharing/continuity without Bluetooth and without IDS:

```bash
uid=$(id -u)

for svc in \
com.apple.sharingd \
com.apple.rapportd \
com.apple.cmio.ContinuityCaptureAgent \
com.apple.mediacontinuityd \
com.apple.amp.mediasharingd
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

for svc in \
com.apple.rapportd \
com.apple.nearbyd
do
  sudo launchctl disable system/$svc
  sudo launchctl bootout system/$svc 2>/dev/null || true
done
```

Stage 2, IDS/account messaging, only if acceptable to break iMessage/FaceTime/Apple ecosystem sync:

```bash
uid=$(id -u)

for svc in \
com.apple.identityservicesd \
com.apple.idsfoundation.IDSRemoteURLConnectionAgent
do
  launchctl disable gui/$uid/$svc
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done
```

Do not include Bluetooth in the first test unless explicitly targeting Bluetooth removal.

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.sharingd \
com.apple.rapportd \
com.apple.cmio.ContinuityCaptureAgent \
com.apple.mediacontinuityd \
com.apple.amp.mediasharingd \
com.apple.identityservicesd \
com.apple.idsfoundation.IDSRemoteURLConnectionAgent
do
  launchctl enable gui/$uid/$svc
done

for svc in \
com.apple.rapportd \
com.apple.nearbyd
do
  sudo launchctl enable system/$svc
done
```

Reboot after rollback.

## Test Result

2026-06-19 temporary bootout Stage 1 succeeded.

Bluetooth and IDS were intentionally not touched.

Before:

```text
sharingd                69.5 MB
identityservicesd       44.4 MB
bluetoothd              35.8 MB
rapportd                29.1 MB
nearbyd                 16.8 MB
ContinuityCaptureAgent  12.5 MB
bluetoothuserd          12.2 MB

BEFORE_SHARING_STAGE1_RSS: 7 processes, 220.5 MB
```

Commands:

```bash
uid=$(id -u)

for svc in \
com.apple.sharingd \
com.apple.rapportd \
com.apple.cmio.ContinuityCaptureAgent \
com.apple.mediacontinuityd \
com.apple.amp.mediasharingd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

for svc in \
com.apple.rapportd \
com.apple.nearbyd
do
  sudo launchctl bootout system/$svc 2>/dev/null || true
done
```

Immediate after:

```text
identityservicesd 44.5 MB
bluetoothd        36.0 MB
nearbyd           16.9 MB
bluetoothuserd    12.2 MB

AFTER_SHARING_STAGE1_RSS: 4 processes, 109.6 MB
```

After 5 seconds, `nearbyd` also exited and only intentional untouched processes remained:

```text
identityservicesd
bluetoothd
bluetoothuserd
```

## Persistent Disable Test

2026-06-20: `sharingd` was disabled as a narrow extreme candidate after Contacts was disabled.

Observed before:

```text
sharingd                ~69 MB RSS
rapportd                ~30 MB RSS
nearbyd                 ~17 MB RSS
ContinuityCaptureAgent  ~13 MB RSS
```

`sharingd` endpoints included:

```text
com.apple.sharing.airdrop.service
com.apple.sharing.handoff.advertising
com.apple.sharing.handoff.scanning
com.apple.sharing.sharesheet
com.apple.sharing.sharesheetrecipients
com.apple.AutoUnlock.AuthenticationHintsProvider
com.apple.SharingServices
com.apple.sharingd.pairedcontactmanager
```

Applied:

```bash
launchctl bootout gui/502/com.apple.sharingd
launchctl disable gui/502/com.apple.sharingd
```

Result:

```text
com.apple.sharingd => disabled
No sharingd process.
launchctl print gui/502/com.apple.sharingd -> service not found.
```

Remaining sharing/continuity processes:

```text
rapportd
nearbyd
ContinuityCaptureAgent
```

Contacts retry impact:

```text
Before corrected Contacts/sharing work: repeated contactsd.persistence retry lines.
After disabling sharingd and corrected contactsd user-domain disables: settled 1 minute contact retry sample showed 0 matching retry lines.
```

Current assessment:

```text
sharingd is a valid extreme toggle.
It breaks AirDrop, Share Sheet nearby recipients, Handoff scanning/advertising, AutoUnlock hints, paired contact manager, and related SharingServices.
It does not remove the whole Continuity stack alone; rapportd, nearbyd, and ContinuityCaptureAgent need separate handling.
Reboot validation on 2026-06-20:

```text
com.apple.sharingd remained disabled.
No sharingd process after reboot.
SSH, sudo, default route, Finder, Dock, ControlCenter, and NotificationCenter remained alive.
```

Observed shortly after reboot:

```text
process_count=389
total_rss_mb=6117.5
```

Observed after ~2 minutes uptime:

```text
process_count=383
total_rss_mb=6215.3
```

Remaining sharing / continuity processes after reboot:

```text
rapportd
nearbyd
ContinuityCaptureAgent
```

Sharing-specific log check:

```text
Only sparse com.apple.SharingServices lookup from coreauthd was observed.
No tight sharingd retry loop seen.
```

Contacts log note:

```text
After sharingd was disabled, contact retry noise was no longer from sharingd.
The remaining current contact retry source was dataaccessd.
```
```
