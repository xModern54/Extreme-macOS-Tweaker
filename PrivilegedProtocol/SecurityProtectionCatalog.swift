import Foundation

struct SecurityProtection: Identifiable, Hashable, Sendable {
  enum Kind: String, Hashable, Sendable {
    case gatekeeper
    case launchServices
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
      title: "Gatekeeper",
      question: "Keep Gatekeeper application assessment enabled?",
      summary: "Checks developer signatures and notarization before downloaded applications are opened.",
      disableConsequence: "Applications from unidentified developers can be opened without Gatekeeper assessment.",
      systemImage: "checkmark.seal",
      kind: .gatekeeper,
      services: [],
      requiresSIPDisabledToDisable: false,
      confirmsBeforeDisable: false
    ),
    SecurityProtection(
      id: "xprotect",
      title: "XProtect Antivirus",
      question: "Keep Apple's built-in malware scanner running?",
      summary: "Background signature scans and malware cleanup jobs.",
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
      title: "Unknown App Protection",
      question: "Keep the unknown-app and quarantine prompts?",
      summary: "syspolicyd. The service behind \"Are you sure you want to open this app?\" and quarantine checks.",
      disableConsequence: "syspolicyd is stopped, LaunchServices quarantine is turned off, and new files in Downloads are stripped of the quarantine flag.",
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
