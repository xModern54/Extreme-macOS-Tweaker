import Foundation

struct SecurityProtection: Identifiable, Hashable, Sendable {
  enum Kind: String, Hashable, Sendable {
    case gatekeeper
    case launchServices
    case dequarantine
  }

  let id: String
  let title: String
  let question: String
  let summary: String
  let disableConsequence: String
  let systemImage: String
  let kind: Kind
  let services: [SecurityProtectionService]
  let requiresSIPDisabledToDisable: Bool
  let confirmsBeforeDisable: Bool
}

struct SecurityProtectionService: Identifiable, Hashable, Sendable {
  enum Domain: String, Hashable, Sendable {
    case system
    case user
    case gui
  }

  let id: String
  let label: String
  let domain: Domain
  let launchdPlistPath: String?
}

enum SecurityProtectionCatalog {
  static let protections: [SecurityProtection] = [
    SecurityProtection(
      id: "gatekeeper",
      title: "Disable Gatekeeper",
      question: "Turn off Gatekeeper application assessment?",
      summary: "Stops signature and notarization checks before downloaded applications are opened.",
      disableConsequence: "Applications from unidentified developers can be opened without Gatekeeper assessment.",
      systemImage: "checkmark.seal",
      kind: .gatekeeper,
      services: [],
      requiresSIPDisabledToDisable: false,
      confirmsBeforeDisable: false
    ),
    SecurityProtection(
      id: "xprotect",
      title: "Disable XProtect Antivirus",
      question: "Stop Apple's built-in malware scanner?",
      summary: "Turns off background signature scans and malware cleanup jobs.",
      disableConsequence: "XProtect will stop scanning for and remediating known malware.",
      systemImage: "shield.lefthalf.filled",
      kind: .launchServices,
      services: [
        service(
          "xprotectd",
          "com.apple.security.xprotectd",
          .system,
          "/System/Library/LaunchDaemons/com.apple.security.xprotectd.plist"
        ),
        service(
          "xprotect-daemon-scan",
          "com.apple.XProtect.daemon.scan",
          .system,
          "/Library/Apple/System/Library/LaunchDaemons/com.apple.XProtect.daemon.scan.plist"
        ),
        service(
          "xprotect-daemon-startup",
          "com.apple.XProtect.daemon.scan.startup",
          .system,
          "/Library/Apple/System/Library/LaunchDaemons/com.apple.XProtect.daemon.scan.startup.plist"
        ),
        service(
          "xprotect-plugin-system",
          "com.apple.XprotectFramework.PluginService",
          .system,
          "/Library/Apple/System/Library/LaunchDaemons/com.apple.XprotectFramework.PluginService.plist"
        ),
        service(
          "xprotect-agent-scan",
          "com.apple.XProtect.agent.scan",
          .gui,
          "/Library/Apple/System/Library/LaunchAgents/com.apple.XProtect.agent.scan.plist"
        ),
        service(
          "xprotect-agent-startup",
          "com.apple.XProtect.agent.scan.startup",
          .gui,
          "/Library/Apple/System/Library/LaunchAgents/com.apple.XProtect.agent.scan.startup.plist"
        ),
        service(
          "xprotect-plugin-user",
          "com.apple.XprotectFramework.PluginService",
          .gui,
          "/Library/Apple/System/Library/LaunchAgents/com.apple.XprotectFramework.PluginService.plist"
        ),
      ],
      requiresSIPDisabledToDisable: true,
      confirmsBeforeDisable: false
    ),
    SecurityProtection(
      id: "system-policy",
      title: "Disable Unknown App Protection",
      question: "Stop unknown-app prompts and LaunchServices quarantine?",
      summary: "Turns off syspolicyd, the service behind \"Are you sure you want to open this app?\"",
      disableConsequence: "syspolicyd is stopped and LaunchServices quarantine is turned off. Global Item Whitelist is turned on with this option.",
      systemImage: "lock.shield",
      kind: .launchServices,
      services: [
        service(
          "syspolicyd",
          "com.apple.security.syspolicy",
          .system,
          "/System/Library/LaunchDaemons/com.apple.security.syspolicy.plist"
        )
      ],
      requiresSIPDisabledToDisable: true,
      confirmsBeforeDisable: true
    ),
    SecurityProtection(
      id: "download-whitelist",
      title: "Global Item Whitelist",
      question: "Strip the quarantine flag from everything in Downloads?",
      summary: "Installs a system LaunchDaemon that clears quarantine on files that land in Downloads.",
      disableConsequence: "A system LaunchDaemon is written to the signed system volume and starts at boot with launchd. New files in Downloads lose their quarantine flag. A restart is required.",
      systemImage: "folder.badge.checkmark",
      kind: .dequarantine,
      services: [],
      requiresSIPDisabledToDisable: true,
      confirmsBeforeDisable: true
    ),
  ]

  static func protection(withID id: String) -> SecurityProtection? {
    protections.first(where: { $0.id == id })
  }

  private static func service(
    _ id: String,
    _ label: String,
    _ domain: SecurityProtectionService.Domain,
    _ launchdPlistPath: String? = nil
  ) -> SecurityProtectionService {
    SecurityProtectionService(
      id: id,
      label: label,
      domain: domain,
      launchdPlistPath: launchdPlistPath
    )
  }
}
