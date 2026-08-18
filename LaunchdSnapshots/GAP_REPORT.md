# Launchd catalog GAP report

Generated for catalog version `2026.08.18.2` (`ExtremeMacTweaker/Resources/TweakCatalog.next.json`).
The shipped `ExtremeMacTweaker/Resources/TweakCatalog.json` (`2026.08.17.1`) was left unchanged.

Category ids in the live catalog are the 2026.08.17.1 set
(`search-desktop`, `siri-intelligence`, `communication-continuity`, `icloud-store`,
`media-location`, `apple-apps`, `privacy-diagnostics`, `accessibility`, `system-network`).
The older 2026.08.12.1 ids from the task brief were not recreated.

## Counts

| Set | Size | Notes |
|---|---:|---|
| OLD (`true` in old system ∪ gui/502) | 389 | system 320, gui 342, both 273 |
| NOW (`true` in current system ∪ gui/502) | 278 | system 106, gui 173 |
| GAP = OLD − NOW | 111 | expected ~111 |
| Current TweakCatalog `services[].label` | 265 | |
| CATALOG (catalog + SecurityProtectionCatalog) | 272 | |
| OLD − CATALOG | 117 | 111 GAP + 6 still-disabled extras |
| GAP ∩ CATALOG (exact label) | 0 | naming mismatches are not exact matches |
| Added to `TweakCatalog.next.json` | 111 | every GAP label |
| Unverified placements (no own mention) | 3 | still attached via neighbor notes |

XProtect / `syspolicyd` labels are in NOW after the Security tab apply, so they are not in GAP.

## Domain rule

Each new service uses the empirical launchd home (LaunchAgent → `gui`/`agent`,
LaunchDaemon → `system`/`daemon`, XPC → `xpcService`) so Tweaker disables the job that
actually runs. When the old snapshot also wrote the other domain, that is recorded in
`old domains` but a second dummy entry was not added, matching how sibling services in
the same feature are modeled.

Exceptions called out in the table: some mdworker / speechsynthesis labels exist only in
the old **system** plist, while the empirical disable recipe and catalog siblings are **gui**.
Those were added as `gui` so Apply hits the real agent.

## Naming mismatches fixed

| Old disabled label | Already in current catalog | New entry |
|---|---|---|
| `com.apple.triald.system` | `com.apple.triald_system` (`triald-system`) | `triald-dot-system` |
| `com.apple.useractivityd` | `com.apple.coreservices.useractivityd` (`useractivityd`) | `useractivityd-short` |
| `com.apple.speech.speechsynthesisd.x86_64` | only `.arm64` | `speechsynthesisd-x86-64` |
| `com.apple.WiFiAgent` | `com.apple.wifi.WiFiAgent` (`wifi-agent`) | `wifi-agent-legacy` |

## GAP placements

| Label | Old domains | Added as | Empirical source | Feature | Group | Why |
|---|---|---|---|---|---|---|
| `com.apple.AOSHeartbeat` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Legacy AOS heartbeat. |
| `com.apple.AirPlayUIAgent` | system,gui | `gui`/agent | com.apple.rapportd/service.md | `airdrop-continuity` | `continuity-sharing` | AirPlay receiver UI. |
| `com.apple.AirPlayXPCHelper` | system,gui | `system`/daemon | com.apple.rapportd/service.md | `airdrop-continuity` | `continuity-sharing` | System AirPlay XPC helper. |
| `com.apple.CoreServicesUIAgent` | gui | `gui`/agent | unverified-neighbor | `download-quarantine` | `download-quarantine` | No own service.md. com.apple.coreservices.uiagent note describes the CoreServicesUIAgent process; this is the matching second label. |
| `com.apple.CryptoTokenKit.ahp` | system | `system`/daemon | com.apple.ctkd/service.md | `smartcards` | `smartcards` | CryptoTokenKit token-extension host (system). |
| `com.apple.CryptoTokenKit.ahp.agent` | gui | `gui`/agent | com.apple.ctkd/service.md | `smartcards` | `smartcards` | CryptoTokenKit token-extension host (user). |
| `com.apple.InstallerDiagnostics.installerdiagd` | system,gui | `system`/daemon | com.apple.usbctelemetryd/service.md | `telemetry-extra` | `telemetry-tails` | Installer diagnostics daemon. |
| `com.apple.InstallerDiagnostics.installerdiagwatcher` | system,gui | `system`/daemon | com.apple.usbctelemetryd/service.md | `telemetry-extra` | `telemetry-tails` | NVRAM-triggered installer diag watcher. |
| `com.apple.MENotificationService` | system,gui | `gui`/agent | com.apple.SoftwareUpdateNotificationManager/service.md | `notifications-extra` | `notifications-peripheral` | Media Extension notifications. |
| `com.apple.ManagedClientAgent.enrollagent` | gui | `gui`/agent | unverified-neighbor | `mdm` | `mdm-remote-management` | No own service.md. Placed next to mdmclient / RemoteManagement as the MDM enrollment agent. |
| `com.apple.Maps.mapspushd` | system,gui | `gui`/agent | com.apple.weatherd/service.md | `location` | `weather-maps-tails` | Maps push daemon. weatherd note groups it with weather/nav satellites. |
| `com.apple.Maps.mapssyncd` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `location` | `weather-maps-tails` | Maps cloud sync (Maps.* spelling). |
| `com.apple.Maps.pushdaemon` | gui | `gui`/agent | com.apple.weatherd/service.md | `location` | `weather-maps-tails` | Maps pushdaemon plist label; weatherd maps it to mapspushd. |
| `com.apple.MobileSMS.MessagesActionExtension` | system,gui | `gui`/agent | com.apple.imagent/service.md | `imessage` | `messages-imessage` | Messages AppIntents extension; launched from linkd. Empirical Messages disable list includes the label. |
| `com.apple.PerfPowerTelemetryClientRegistrationService` | system,gui | `system`/xpcService | com.apple.PerfPowerServices/service.md | `power-diagnostics` | `power-diagnostics` | PowerLog telemetry client registration XPC next to PerfPowerServices. |
| `com.apple.RemoteManagementAgent` | system,gui | `gui`/agent | com.apple.remotemanagementd/service.md | `mdm` | `mdm-remote-management` | Remote Management user agent. |
| `com.apple.SSInvitationAgent` | gui | `gui`/agent | com.apple.followupd/service.md | `airdrop-continuity` | `continuity-remainder` | Screen Sharing invitation agent. |
| `com.apple.Safari.PasswordBreachAgent` | gui | `gui`/agent | com.apple.SafariPlatformSupport.Helper/service.md | `safari-helpers` | `safari-helpers` | Safari password-breach scanner. |
| `com.apple.SafariHistoryServiceAgent` | gui | `gui`/agent | com.apple.SafariPlatformSupport.Helper/service.md | `safari-helpers` | `safari-helpers` | Safari history service agent. |
| `com.apple.SafariLaunchAgent` | gui | `gui`/agent | com.apple.SafariPlatformSupport.Helper/service.md | `safari-helpers` | `safari-helpers` | Safari launch agent. |
| `com.apple.StatusKitAgent` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Status/presence kit sync. |
| `com.apple.UserNotificationCenterAgent-LoginWindow` | system | `system`/daemon | com.apple.SoftwareUpdateNotificationManager/service.md | `notifications-extra` | `notifications-peripheral` | Legacy UNC at login window. Empirical disable list treated it as gui; old snapshot only has the system key. Added as system per snapshot rule. |
| `com.apple.UserPictureSyncAgent` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Apple ID avatar sync. |
| `com.apple.WiFiAgent` | gui | `gui`/agent | com.apple.wifip2pd/service.md | `wifi-agent` | `wifi-menu-agent` | Real Wi‑Fi menu-agent label. Catalog already has com.apple.wifi.WiFiAgent. |
| `com.apple.accessibility.MotionTrackingAgent` | gui | `gui`/agent | com.apple.followupd/service.md | `accessibility-overlays` | `accessibility-ui-overlays` | Motion-tracking accessibility agent. |
| `com.apple.appleh13camerad` | system,gui | `system`/daemon | com.apple.cmio.registerassistantservice/service.md | `camera` | `camera-cmio` | Older/Intel camera driver; idle on Apple silicon. |
| `com.apple.bookdatastored` | system,gui | `gui`/agent | com.apple.itunescloudd/service.md | `media-stores` | `media-stores` | Apple Books data store; paired with itunescloudd in media-stores-off. |
| `com.apple.callintelligenced` | gui | `gui`/agent | com.apple.telephonyutilities.callservicesd/service.md | `facetime` | `facetime-callkit` | Call intelligence helper next to callservicesd. |
| `com.apple.ckdiscretionaryd` | system,gui | `gui`/agent | com.apple.cloudsettingssyncagent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Discretionary CloudKit tasks. |
| `com.apple.cloudpaird` | gui | `gui`/agent | com.apple.followupd/service.md | `bluetooth-user-pairing` | `bluetooth-user` | Cloud pairing leftover. Related plist/family of BTServer.cloudpairing / audioaccessoryd. |
| `com.apple.cmfsyncagent` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | CoreMedia file sync agent. |
| `com.apple.cmio.LaunchCMIOUserExtensionsAgent` | system,gui | `gui`/agent | com.apple.cmio.registerassistantservice/service.md | `camera` | `camera-cmio` | CMIO user-extension launcher. |
| `com.apple.cmio.iOSScreenCaptureAssistant` | system,gui | `system`/daemon | com.apple.cmio.registerassistantservice/service.md | `camera` | `camera-cmio` | iOS screen-capture assistant. |
| `com.apple.cmio.videodriverkithostextension` | system,gui | `system`/daemon | com.apple.cmio.registerassistantservice/service.md | `camera` | `camera-cmio` | VideoDriverKit host extension. |
| `com.apple.coredatad` | system,gui | `gui`/agent | com.apple.cloudsettingssyncagent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | CloudKit Core Data sync. |
| `com.apple.corespotlightservice` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | CoreSpotlight XPC companion in the Spotlight disable recipe. |
| `com.apple.ctkbind` | gui | `gui`/agent | com.apple.ctkd/service.md | `smartcards` | `smartcards` | CryptoTokenKit bind/pair helper. |
| `com.apple.dataaccess.dataaccessd` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | DataAccess CalDAV/CardDAV/Exchange accounts. contactsd notes leftover retries came from here. |
| `com.apple.devicemanagementclient.managedeventsd` | system,gui | `system`/daemon | com.apple.remotemanagementd/service.md | `mdm` | `mdm-remote-management` | Managed device events daemon. |
| `com.apple.diagnosticextensions.osx.spotlight.helper` | system,gui | `system`/daemon | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Spotlight diagnostic extension helper. |
| `com.apple.diagnosticextensions.osx.timemachine.helper` | system,gui | `system`/daemon | com.apple.backupd-helper/service.md | `time-machine` | `time-machine` | Time Machine Feedback Assistant diagnostic helper. |
| `com.apple.diagnosticextensionsd` | system,gui | `gui`/agent | com.apple.inputanalyticsd/service.md | `telemetry-extra` | `telemetry-tails` | Diagnostic Extensions XPC host. |
| `com.apple.diagnostics_agent` | system,gui | `gui`/agent | com.apple.inputanalyticsd/service.md | `telemetry-extra` | `telemetry-tails` | Per-user diagnostics collection agent. |
| `com.apple.ecosystemagent` | system,gui | `gui`/agent | com.apple.ecosystemd/service.md | `telemetry-extra` | `telemetry-tails` | Ecosystem/Rosetta warning user agent. |
| `com.apple.ecosystemanalyticsd` | system,gui | `system`/daemon | com.apple.ecosystemd/service.md | `telemetry-extra` | `telemetry-tails` | Ecosystem/Rosetta analytics daemon. |
| `com.apple.exchange.exchangesyncd` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Exchange calendar/mail sync. |
| `com.apple.fairplaydeviceidentityd` | system,gui | `system`/daemon | com.apple.amsaccountsd/service.md | `appstore-nuclear-install` | `appstore-stage-c` | FairPlay device identity; Stage B optional next to fairplayd. |
| `com.apple.familycontrols` | system | `system`/daemon | com.apple.followupd/service.md | `contacts` | `people-family-calendar` | Family Controls system daemon. |
| `com.apple.familycontrols.useragent` | gui | `gui`/agent | com.apple.followupd/service.md | `contacts` | `people-family-calendar` | Family Controls user agent. |
| `com.apple.ftp-proxy` | system | `system`/daemon | com.apple.followupd/service.md | `netbios` | `netbios` | Legacy FTP proxy from the leftover system trio. |
| `com.apple.ftpd` | system | `system`/daemon | unverified-neighbor | `netbios` | `netbios` | No own service.md. Placed with ftp-proxy as the legacy FTP server; disabling a server does not affect login/SSH. |
| `com.apple.iCloudUserNotifications` | gui | `gui`/agent | com.apple.followupd/service.md | `notifications-extra` | `notifications-peripheral` | Legacy iCloud user-notifications label (distinct from iCloudUserNotificationsd). |
| `com.apple.icloudmailagent` | system,gui | `gui`/agent | com.apple.cloudsettingssyncagent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | iCloud Mail background agent. |
| `com.apple.icloudwebd` | system,gui | `gui`/agent | com.apple.cloudsettingssyncagent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | iCloud web helpers. |
| `com.apple.imautomatichistorydeletionagent` | gui | `gui`/agent | com.apple.followupd/service.md | `imessage` | `messages-imessage` | iMessage automatic history deletion agent. |
| `com.apple.installcoordination_proxy` | system,gui | `system`/daemon | com.apple.amsaccountsd/service.md | `appstore-nuclear-install` | `appstore-stage-c` | Install Coordination proxy; Stage B optional next to installcoordinationd. |
| `com.apple.intelligencecontextd` | gui | `gui`/agent | com.apple.followupd/service.md | `apple-intelligence` | `apple-intelligence` | Apple Intelligence context daemon from the idle-consumer leftover batch. |
| `com.apple.intelligenceflowd` | gui | `gui`/agent | com.apple.followupd/service.md | `apple-intelligence` | `apple-intelligence` | Apple Intelligence flow daemon from the leftover batch. |
| `com.apple.knowledge-agent` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Search-knowledge agent in the Spotlight disable recipe. |
| `com.apple.knowledgeconstructiond` | system,gui | `gui`/agent | com.apple.generativeexperiencesd/service.md | `apple-intelligence` | `apple-intelligence` | Intelligence Platform knowledge construction. Also in the Spotlight recipe; placed with the generative-AI sibling. |
| `com.apple.managedappdistributionagent` | system,gui | `gui`/agent | com.apple.remotemanagementd/service.md | `mdm` | `mdm-remote-management` | Managed/VPP app distribution user agent. |
| `com.apple.managedappdistributiond` | system,gui | `system`/daemon | com.apple.remotemanagementd/service.md | `mdm` | `mdm-remote-management` | Managed/VPP app distribution daemon. |
| `com.apple.managedcorespotlightd` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Managed CoreSpotlight daemon in the Spotlight disable recipe. |
| `com.apple.maps.destinationd` | gui | `gui`/agent | com.apple.followupd/service.md | `location` | `weather-maps-tails` | Maps destination helper. |
| `com.apple.maps.mapssyncd` | gui | `gui`/agent | com.apple.followupd/service.md | `location` | `weather-maps-tails` | Maps sync with lowercase maps.* label; distinct from Maps.mapssyncd. |
| `com.apple.mdworker.application` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Application mdworker. Old snapshot only had a system key; empirical recipe and sibling mdworker.shared are gui. |
| `com.apple.mdworker.mail` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Mail mdworker. Snapshot system-only; empirical recipe is gui. |
| `com.apple.mdworker.single.arm64` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Single-shot ARM64 mdworker. Snapshot system-only; empirical recipe is gui. |
| `com.apple.mdworker.single.x86_64` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Single-shot x86_64 mdworker. Snapshot system-only; empirical recipe is gui. |
| `com.apple.mdworker.sizing` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Sizing mdworker. Snapshot system-only; empirical recipe is gui. |
| `com.apple.mediastream.mstreamd` | gui | `gui`/agent | com.apple.followupd/service.md | `photos-library` | `photos-library` | My Photo Stream. |
| `com.apple.metadata.mdflagwriter` | system | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Metadata flag writer. Snapshot system-only; empirical recipe is gui. |
| `com.apple.metadata.mds.index.readonly` | gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Read-only MDS index helper. Old snapshot gui; empirical system list also mentions it. |
| `com.apple.metadata.mds.spindump` | system,gui | `system`/daemon | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | MDS spindump helper in the Spotlight system disable list. |
| `com.apple.mobile.notification_proxy` | system,gui | `system`/daemon | com.apple.SoftwareUpdateNotificationManager/service.md | `notifications-extra` | `notifications-peripheral` | iOS device notification proxy. |
| `com.apple.msrpc.mdssvc` | system,gui | `system`/daemon | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | SMB/MDS RPC service in the Spotlight system disable list. |
| `com.apple.naturallanguaged` | gui | `gui`/agent | com.apple.followupd/service.md | `apple-intelligence` | `apple-intelligence` | Natural-language daemon from the leftover batch. |
| `com.apple.navd` | system,gui | `gui`/agent | com.apple.weatherd/service.md | `location` | `weather-maps-tails` | Turn-by-turn navigation daemon. |
| `com.apple.newsd` | gui | `gui`/agent | com.apple.followupd/service.md | `family-followup` | `family-followup` | News daemon from the idle-consumer leftover batch. |
| `com.apple.noticeboard.agent` | system,gui | `gui`/agent | com.apple.SoftwareUpdateNotificationManager/service.md | `notifications-extra` | `notifications-peripheral` | Noticeboard alerts. |
| `com.apple.parsec-fbf` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Parsec feedback companion in the Spotlight disable recipe. |
| `com.apple.parsecd` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | Apple search suggestions (parsec). Bundled with Spotlight in the working disable recipe. |
| `com.apple.perfpowermetricd` | system,gui | `system`/daemon | com.apple.usbctelemetryd/service.md | `telemetry-extra` | `telemetry-tails` | PerfPower metric monitor XPC; idle telemetry tail. |
| `com.apple.powerlogHelperd` | system,gui | `system`/daemon | com.apple.usbctelemetryd/service.md | `telemetry-extra` | `telemetry-tails` | PowerLog helper. usbctelemetryd groups it as idle telemetry, not core power. |
| `com.apple.progressd` | gui | `gui`/agent | com.apple.followupd/service.md | `education` | `education` | ClassKit progress daemon; studentd notes class-membership events from progressd. |
| `com.apple.ptpcamerad` | system,gui | `gui`/agent | com.apple.cmio.registerassistantservice/service.md | `camera` | `camera-cmio` | PTP/USB camera daemon. |
| `com.apple.replicatord` | system,gui | `gui`/agent | com.apple.rapportd/service.md | `airdrop-continuity` | `continuity-sharing` | Continuity state replicator. |
| `com.apple.screensharing` | system | `system`/daemon | com.apple.sharingd/service.md | `airdrop-continuity` | `continuity-remainder` | Screen Sharing daemon. remotemanagementd notes call this a separate group from MDM. |
| `com.apple.screensharing.agent` | gui | `gui`/agent | com.apple.sharingd/service.md | `airdrop-continuity` | `continuity-remainder` | Screen Sharing user agent. |
| `com.apple.screensharing.menuextra` | gui | `gui`/agent | com.apple.sharingd/service.md | `airdrop-continuity` | `continuity-remainder` | Screen Sharing menu extra. |
| `com.apple.security.keychain-circle-notification` | system,gui | `gui`/agent | com.apple.SoftwareUpdateNotificationManager/service.md | `notifications-extra` | `notifications-peripheral` | iCloud Keychain circle approval UI. |
| `com.apple.sidecar-hid-relay` | gui | `gui`/agent | com.apple.followupd/service.md | `airdrop-continuity` | `continuity-remainder` | Sidecar HID relay next to sidecar-relay. |
| `com.apple.siriactionsd` | system,gui | `gui`/agent | com.apple.corespeechd/service.md | `siri-dictation` | `speech-siri` | Siri Shortcuts / actions daemon. Also in the Spotlight note as search-adjacent. |
| `com.apple.siriinferenced` | system,gui | `gui`/agent | com.apple.corespeechd/service.md | `siri-dictation` | `speech-siri` | Siri inference daemon. |
| `com.apple.siriknowledged` | system,gui | `gui`/agent | com.apple.corespeechd/service.md | `siri-dictation` | `speech-siri` | Siri knowledge daemon. |
| `com.apple.sirittsd` | system,gui | `gui`/agent | com.apple.corespeechd/service.md | `siri-dictation` | `speech-siri` | Siri TTS daemon. |
| `com.apple.speech.speechsynthesisd.x86_64` | system | `gui`/agent | com.apple.corespeechd/service.md | `siri-dictation` | `speech-siri` | Naming/arch gap: catalog only had speechsynthesisd.arm64. Empirical recipe disables the x86_64 agent in gui; old snapshot wrote a system key. |
| `com.apple.spotlightknowledged.importer` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | spotlightknowledged importer worker. |
| `com.apple.spotlightknowledged.updater` | system,gui | `gui`/agent | com.apple.metadata.mds/service.md | `spotlight` | `spotlight-core` | spotlightknowledged updater worker. |
| `com.apple.suggestd` | system,gui | `gui`/agent | com.apple.routined/service.md | `proactive-suggestions` | `routine-proactive` | Suggestions daemon. Spotlight recipe also lists it; placed with CoreRoutine / proactive suggestions. |
| `com.apple.symptomsd-diag` | system,gui | `system`/daemon | com.apple.symptomsd/service.md | `network-symptoms` | `network-symptoms` | Network symptom diagnostics daemon. |
| `com.apple.symptomsd-diag.agent` | system,gui | `gui`/agent | com.apple.inputanalyticsd/service.md | `network-symptoms` | `network-symptoms` | GUI companion for symptomsd-diag. |
| `com.apple.syncservices.SyncServer` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Legacy Sync Services server. |
| `com.apple.syncservices.uihandler` | system,gui | `gui`/agent | com.apple.SafariBookmarksSyncAgent/service.md | `icloud-settings-sync` | `icloud-sync-tails` | Legacy Sync Services UI. |
| `com.apple.tipsd` | gui | `gui`/agent | com.apple.helpd/service.md | `help-index` | `help-indexer` | Tips daemon. helpd listens for tips.content-updated; followupd also lists it as a leftover. |
| `com.apple.triald.system` | system,gui | `system`/daemon | com.apple.triald/service.md | `apple-trial` | `apple-trial` | Real LaunchDaemon label is com.apple.triald.system. Catalog already has the underscore alias com.apple.triald_system. |
| `com.apple.useractivityd` | gui | `gui`/agent | com.apple.useractivityd/service.md | `airdrop-continuity` | `continuity-sharing` | Short Handoff label. Catalog already has com.apple.coreservices.useractivityd. |
| `com.apple.videoconference.camera` | gui | `gui`/agent | com.apple.telephonyutilities.callservicesd/service.md | `facetime` | `facetime-callkit` | AVConference camera Mach service from avconferenced.plist. |
| `com.apple.videosubscriptionsd` | gui | `gui`/agent | com.apple.followupd/service.md | `family-followup` | `family-followup` | TV/video subscription agent from the leftover batch. |
| `com.apple.watchlistd` | gui | `gui`/agent | com.apple.followupd/service.md | `family-followup` | `family-followup` | TV watchlist agent from the leftover batch. |
| `com.apple.wifianalyticsd` | system,gui | `system`/daemon | com.apple.symptomsd/service.md | `network-symptoms` | `network-symptoms` | Wi-Fi analytics. symptomsd note keeps WiFiAgent/airportd enabled. |

## Unverified (no `EmpericalData` mention)

These three labels do not appear in any `service.md`. They were still added because a neighbor note makes the home obvious:

- `com.apple.CoreServicesUIAgent` → `download-quarantine` / `download-quarantine` — No own service.md. com.apple.coreservices.uiagent note describes the CoreServicesUIAgent process; this is the matching second label.
- `com.apple.ManagedClientAgent.enrollagent` → `mdm` / `mdm-remote-management` — No own service.md. Placed next to mdmclient / RemoteManagement as the MDM enrollment agent.
- `com.apple.ftpd` → `netbios` / `netbios` — No own service.md. Placed with ftp-proxy as the legacy FTP server; disabling a server does not affect login/SSH.

## Not added, and why

| Label | Reason |
|---|---|
| `com.openssh.sshd` | Old and current system plists set this to false (explicitly left enabled). Do not catalog. |
| `com.apple.WindowServer` | Not in GAP. Login/display server — never disable. |
| `loginwindow / com.apple.loginwindow` | Not in GAP. Would break login. |

No GAP label is WindowServer, loginwindow, or sshd.

## OLD extras still disabled now — added in 2026.08.18.2

These six were `true` in the old snapshot **and** are still `true` on the test Mac
(`codex` / `c`, macOS 26.5.1). They were not in GAP (already disabled after Apply),
then inspected over SSH and folded into existing groups. No launchd enable/disable
was done on the live machine.

| Label | Old / now domains | Added as | Feature / group | What it is (from `c`) |
|---|---|---|---|---|
| `com.apple.Siri.agent` | gui / gui | `gui`/agent `siri-agent` | `siri-dictation` / `speech-siri` | LaunchAgent for `/System/Library/CoreServices/Siri.app` (`Siri launchd`). Mach: `siri.activation`, `siri.invoke`, `Siri.running`. The Siri UI/activation app. Listed as already disabled in `corespeechd/service.md`. Not running while disabled. |
| `com.apple.mdmclient.daemon.runatboot` | system,gui / system | `system`/daemon `mdmclient-runatboot` | `mdm` / `mdm-remote-management` | LaunchDaemon `/usr/libexec/mdmclient rundaemon`, `RunAtLoad`. Boot hook next to `mdmclient.daemon` (`mdmclient daemon` + APS push). In the remotemanagementd 8-label recipe. Mac is not DEP/MDM enrolled. |
| `com.apple.FolderActionsDispatcher` | gui / gui | `gui`/agent `folder-actions-dispatcher` | `misc-trims` / `misc-coding-trims` | LaunchAgent `FolderActionsDispatcher.app`, KeepAlive+RunAtLoad. man: monitors the filesystem and starts configured Folder Action scripts; also owns Folder Actions settings. AppleScript automation leftover. |
| `com.apple.ScriptMenuApp` | gui / gui | `gui`/agent `script-menu-app` | `misc-trims` / `misc-coding-trims` | LaunchAgent for `/System/Library/CoreServices/Script Menu.app`, Aqua-only, KeepAlive+RunAtLoad. Menu-bar extra that lists user AppleScripts. Same automation leftover family as Folder Actions. |
| `com.apple.appleseed.seedusaged.postinstall` | gui / gui | `gui`/agent `seedusaged-postinstall` | `onboarding-feedback` / `onboarding-feedback` | LaunchAgent inside Feedback Assistant: `seedusaged oneShot`, Aqua, RunAtLoad. Sibling `seedusaged` is a daily noon job; `fbahelperd` is the privileged helper. AppleSeed/Feedback usage one-shot next to `feedbackd`. |
| `com.apple.CSCSupportd` | system / system | `system`/daemon `csc-supportd` | `hardware-repair` / `hardware-repair` | LaunchDaemon `/usr/libexec/CSCSupportd`. man CSCSupportd(8): **Core System Check Support** daemon — returns a system property on request. Remote XPC + entitlement `com.apple.private.CSCSupport.antenna-access`. Hardware/antenna factory-check helper, not login-critical. Placed with `corerepaird` / `mobilerepaird`. |

After this pass, OLD − (next catalog + Security) = **0**.

## False keys ignored

Old snapshot `false` (explicitly left enabled) includes Bluetooth core, `cloudpaird` on **system**
(gui `cloudpaird` was `true` and is in GAP), `corebrightnessd`, `mediaremoted`, `systemstatusd`,
and `com.openssh.sshd`. Those `false` keys were not imported.
`disabled.501.plist` (user xmodern) was ignored.

## New catalog file

- Path: `ExtremeMacTweaker/Resources/TweakCatalog.next.json`
- `catalogVersion`: `2026.08.18.2`
- Services: 265 → 382 (+111 GAP + 6 still-disabled leftovers)
- Service groups: 83 (existing groups extended; no new categories)

