# Enterprise & MDM Full Eradication Catalog (macOS 27 Golden Gate)

## Overview

This catalog contains the **complete, exhaustive map of all Apple Mobile Device Management (MDM), Declarative Device Management (DDM), ManagedClient (MCX), RemoteManagement, and Beta Enrollment files and property lists** on macOS 27 Golden Gate.

These components enforce corporate supervision, educational restrictions, policy payloads, and remote management check-ins. On a personal Mac, they are entirely useless and consume background resources and network bandwidth.

---

## 1. LaunchDaemons (System Domain)

```text
/System/Library/LaunchDaemons/com.apple.ManagedClient.enroll.plist
/System/Library/LaunchDaemons/com.apple.ManagedClient.mechanism.plist
/System/Library/LaunchDaemons/com.apple.ManagedClient.plist
/System/Library/LaunchDaemons/com.apple.ManagedClient.startup.plist
/System/Library/LaunchDaemons/com.apple.betaenrollmentd.plist
/System/Library/LaunchDaemons/com.apple.deviceconfigurationd.plist
/System/Library/LaunchDaemons/com.apple.devicemanagementclient.managedappsd.plist
/System/Library/LaunchDaemons/com.apple.devicemanagementclient.teslad.plist
/System/Library/LaunchDaemons/com.apple.mdmclient.daemon.runatboot.plist
```

---

## 2. LaunchAgents (User GUI Domain)

```text
/System/Library/LaunchAgents/com.apple.DeviceConfigurationAgent.plist
/System/Library/LaunchAgents/com.apple.ManagedClientAgent.agent.plist
/System/Library/LaunchAgents/com.apple.betaenrollmentagent.plist
/System/Library/LaunchAgents/com.apple.devicemanagementclient.ManagedAppsAgent.plist
/System/Library/LaunchAgents/com.apple.devicemanagementclient.alertagent.plist
```

---

## 3. CoreServices Applications

```text
/System/Library/CoreServices/ManagedClient.app
/System/Library/CoreServices/ManagedClient.app/Contents/MacOS/ManagedClient
/System/Library/CoreServices/ManagedClient.app/Contents/Resources/ManagedClientAgent
```

---

## 4. Binaries & Helpers

```text
/usr/libexec/betaenrollmentagent
/usr/libexec/betaenrollmentd
/usr/libexec/managedappsd
/usr/libexec/managedeventsd
/usr/libexec/mdmclient
/System/Library/PrivateFrameworks/DeviceConfiguration.framework/Versions/A/deviceconfigurationd
/System/Library/PrivateFrameworks/DeviceConfiguration.framework/Versions/A/DeviceConfigurationAgent
```

---

## 5. Configuration Provider Registrations & Specs

```text
/System/Library/DeviceConfiguration/ProviderRegistrations/ProviderPriorities.plist
/System/Library/DeviceConfiguration/ProviderRegistrations/com.apple.AutomaticAssessmentConfiguration.plist
/System/Library/DeviceConfiguration/ProviderRegistrations/com.apple.RemoteManagement.DeviceConfigurationExtension.plist
/System/Library/DeviceConfiguration/ProviderRegistrations/com.apple.managedsettings.plist
/System/Library/DeviceConfiguration/Specs/com.apple.Accessibility.plist
/System/Library/DeviceConfiguration/Specs/com.apple.CalendarUI.plist
/System/Library/DeviceConfiguration/Specs/com.apple.WebContentRestrictions.plist
/System/Library/DeviceConfiguration/Specs/com.apple.modelcatalog.plist
```

---

## 6. RemoteManagement.framework XPCServices (22 Subscribers)

```text
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ASConfigurationSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/AccountSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/AssetCacheSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/BackgroundTaskManagementSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/DeviceConfigurationSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/DiskManagementSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ExtensibleSSOSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/InteractiveLegacyProfilesSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/LegacyProfilesSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagedAppsSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagedConfigurationFilesSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagedPreferencesSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagedSettingsSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagedStatusSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ManagementTestSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/MigrationSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/NetworkExtensionSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/PasscodeSettingsSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/PowerSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/ScreenSharingSubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/SecuritySubscriber.xpc
/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/SoftwareUpdateSubscriber.xpc
```

---

## 7. ConfigurationProfiles.framework XPCServices (25 Profile Handlers)

```text
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/AirPlayService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/AppleService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/AssessmentService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/AssetCacheProfilePlugin.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/BTMProfileService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/CardDAVService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/CertificateService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/ClassroomMCXService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/EraseService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/ExchangeService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/ExecutionPolicyService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/FeatureFlagsProfileService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/FileVaultEscrowService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/FirewallService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/FirmwarePasswordService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/FontService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/LOMXPCService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/MAIDService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/MDMService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/PlugInKitService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/RemoteManagementMCXProfile.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/RemoteManagementMCXService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/SampleService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/SingleSignOnService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/SystemExtensionsMDM.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/SystemPolicyService.xpc
/System/Library/PrivateFrameworks/ConfigurationProfiles.framework/XPCServices/TCCProfileService.xpc
```

---

## 8. Full SSV Eradication Recipe (Root Helper Plan)

To permanently wipe all MDM and Enterprise surveillance infrastructure from the boot volume:

1. **Mount Writable Base Snapshot:**
   ```bash
   mount_apfs -o rw /dev/diskXsY /Volumes/SystemRW
   ```

2. **Disable / Move LaunchDaemons & LaunchAgents Plists:**
   ```bash
   for f in \
     com.apple.ManagedClient.enroll.plist \
     com.apple.ManagedClient.mechanism.plist \
     com.apple.ManagedClient.plist \
     com.apple.ManagedClient.startup.plist \
     com.apple.betaenrollmentd.plist \
     com.apple.deviceconfigurationd.plist \
     com.apple.devicemanagementclient.managedappsd.plist \
     com.apple.devicemanagementclient.teslad.plist \
     com.apple.mdmclient.daemon.runatboot.plist; do
     mv "/Volumes/SystemRW/System/Library/LaunchDaemons/$f" "/Volumes/SystemRW/System/Library/LaunchDaemons/$f.disabled" 2>/dev/null || true
   done

   for f in \
     com.apple.DeviceConfigurationAgent.plist \
     com.apple.ManagedClientAgent.agent.plist \
     com.apple.betaenrollmentagent.plist \
     com.apple.devicemanagementclient.ManagedAppsAgent.plist \
     com.apple.devicemanagementclient.alertagent.plist; do
     mv "/Volumes/SystemRW/System/Library/LaunchAgents/$f" "/Volumes/SystemRW/System/Library/LaunchAgents/$f.disabled" 2>/dev/null || true
   done
   ```

3. **Neutralize XPC Subscribers:**
   ```bash
   mv "/Volumes/SystemRW/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices" \
      "/Volumes/SystemRW/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices.disabled" 2>/dev/null || true
   ```

4. **Seal Snapshot & Bless:**
   ```bash
   bless --folder /Volumes/SystemRW/System/Library/CoreServices --bootefi --create-snapshot
   ```
