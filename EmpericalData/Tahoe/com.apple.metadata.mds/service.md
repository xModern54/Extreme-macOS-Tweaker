# Spotlight / Metadata Search

## Basics

- **Main labels:** `com.apple.metadata.mds`, `com.apple.Spotlight`, `com.apple.corespotlightd`
- **Processes:** `mds`, `mds_stores`, `mdworker`, `mdbulkimport`, `mdwrite`, `Spotlight`, `corespotlightd`, `spotlightknowledged`
- **Domains:** `system`, `gui/<uid>`
- **Category:** `spotlight`
- **Risk:** `2`
- **Verdict:** `disable for coding profile`

## What It Does

Spotlight file indexing, metadata search, CoreSpotlight, Apple search suggestions, knowledge/suggestion agents, Siri-adjacent search intelligence, and metadata import workers.

For this coding-only setup, Spotlight is not needed except as an occasional app launcher. The memory and background activity cost is too high.

## Working Disable Recipe

First disable indexing only. Do not erase stores and do not use `mdutil -d` for the persistent recipe.

```bash
sudo mdutil -a -i off
```

Then persistently disable the launchd jobs.

```bash
uid=$(id -u)

for svc in \
com.apple.Spotlight \
com.apple.corespotlightd \
com.apple.corespotlightservice \
com.apple.knowledge-agent \
com.apple.knowledgeconstructiond \
com.apple.managedcorespotlightd \
com.apple.mdworker.application \
com.apple.mdworker.mail \
com.apple.mdworker.shared \
com.apple.mdworker.single.arm64 \
com.apple.mdworker.single.x86_64 \
com.apple.mdworker.sizing \
com.apple.metadata.mdbulkimport \
com.apple.metadata.mdflagwriter \
com.apple.metadata.mdwrite \
com.apple.parsec-fbf \
com.apple.parsecd \
com.apple.siriactionsd \
com.apple.siriinferenced \
com.apple.siriknowledged \
com.apple.sirittsd \
com.apple.spotlightknowledged \
com.apple.spotlightknowledged.importer \
com.apple.spotlightknowledged.updater \
com.apple.suggestd
do
  launchctl disable gui/$uid/$svc
done

for svc in \
com.apple.metadata.mds \
com.apple.metadata.mds.index \
com.apple.metadata.mds.index.readonly \
com.apple.metadata.mds.scan \
com.apple.metadata.mds.spindump \
com.apple.diagnosticextensions.osx.spotlight.helper \
com.apple.msrpc.mdssvc
do
  sudo launchctl disable system/$svc
done
```

Optional immediate unload after disabling:

```bash
uid=$(id -u)

for svc in \
com.apple.Spotlight \
com.apple.corespotlightd \
com.apple.corespotlightservice \
com.apple.knowledge-agent \
com.apple.knowledgeconstructiond \
com.apple.managedcorespotlightd \
com.apple.mdworker.application \
com.apple.mdworker.mail \
com.apple.mdworker.shared \
com.apple.mdworker.single.arm64 \
com.apple.mdworker.single.x86_64 \
com.apple.mdworker.sizing \
com.apple.metadata.mdbulkimport \
com.apple.metadata.mdflagwriter \
com.apple.metadata.mdwrite \
com.apple.parsec-fbf \
com.apple.parsecd \
com.apple.siriactionsd \
com.apple.siriinferenced \
com.apple.siriknowledged \
com.apple.sirittsd \
com.apple.spotlightknowledged \
com.apple.spotlightknowledged.importer \
com.apple.spotlightknowledged.updater \
com.apple.suggestd
do
  launchctl bootout gui/$uid/$svc 2>/dev/null || true
done

for svc in \
com.apple.metadata.mds \
com.apple.metadata.mds.index \
com.apple.metadata.mds.index.readonly \
com.apple.metadata.mds.scan \
com.apple.metadata.mds.spindump \
com.apple.diagnosticextensions.osx.spotlight.helper \
com.apple.msrpc.mdssvc
do
  sudo launchctl bootout system/$svc 2>/dev/null || true
done
```

## Rollback

```bash
uid=$(id -u)

for svc in \
com.apple.Spotlight \
com.apple.corespotlightd \
com.apple.corespotlightservice \
com.apple.knowledge-agent \
com.apple.knowledgeconstructiond \
com.apple.managedcorespotlightd \
com.apple.mdworker.application \
com.apple.mdworker.mail \
com.apple.mdworker.shared \
com.apple.mdworker.single.arm64 \
com.apple.mdworker.single.x86_64 \
com.apple.mdworker.sizing \
com.apple.metadata.mdbulkimport \
com.apple.metadata.mdflagwriter \
com.apple.metadata.mdwrite \
com.apple.parsec-fbf \
com.apple.parsecd \
com.apple.siriactionsd \
com.apple.siriinferenced \
com.apple.siriknowledged \
com.apple.sirittsd \
com.apple.spotlightknowledged \
com.apple.spotlightknowledged.importer \
com.apple.spotlightknowledged.updater \
com.apple.suggestd
do
  launchctl enable gui/$uid/$svc
done

for svc in \
com.apple.metadata.mds \
com.apple.metadata.mds.index \
com.apple.metadata.mds.index.readonly \
com.apple.metadata.mds.scan \
com.apple.metadata.mds.spindump \
com.apple.diagnosticextensions.osx.spotlight.helper \
com.apple.msrpc.mdssvc
do
  sudo launchctl enable system/$svc
done

sudo mdutil -a -i on
sudo mdutil -a -E
```

Reboot after rollback.

## Verified Result

Tested on 2026-06-19 on Target Mac under `codexadmin`.

- Before tuning, Spotlight/metadata stack was observed between about `500-1400 MB RSS`, depending on boot/indexing state.
- `sudo mdutil -a -i off` alone persisted after reboot and prevented the `mdworker_shared` storm.
- Full temporary `bootout` dropped the broad Spotlight/search stack from `387.9 MB RSS` to `43.1 MB RSS`.
- Persistent `launchctl disable` survived reboot.
- After reboot, process filter for `mds|mdworker|spotlight|corespotlight|metadata|mdbulkimport|mdwrite|knowledge|parsec|suggest|siri` returned `0 processes, 0.0 MB RSS` at 12 seconds uptime.
- Four minutes after boot, the only remaining broad-filter match was `SAExtensionOrchestrator` at about `17.8 MB`; no Spotlight/metadata core processes were running.
- SSH, console autologin, and passwordless sudo still worked.

## Do Not Use For Persistent Recipe

These commands were tested and caused bad behavior on this macOS:

```bash
sudo mdutil -a -d
sudo mdutil -X /
sudo mdutil -X /System/Volumes/Data
sudo mdutil -X /System/Volumes/Preboot
```

Before reboot they showed `Indexing and searching disabled`, but after reboot Spotlight re-enabled indexing and launched a large `mdworker_shared` storm. The safer persistent first step is only:

```bash
sudo mdutil -a -i off
```

## Notes

`com.apple.metadata.mds_stores` was not found as a launchd label on this system. `mds_stores` appears as a process, not a service label.
