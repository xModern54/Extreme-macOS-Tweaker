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
      requiresSIPDisabledToDisable: false
    ),
    SecurityProtection(
      id: "xprotect",
      title: "XProtect",
      question: "Keep built-in malware scanning enabled?",
      summary: "Runs Apple's signature scanner and malware-remediation jobs in the background.",
      disableConsequence: "macOS will stop scanning for and remediating malware with XProtect.",
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
      requiresSIPDisabledToDisable: true
    ),
    SecurityProtection(
      id: "system-policy",
      title: "System Policy (syspolicyd)",
      question: "Keep syspolicyd application policy services enabled?",
      summary: "Provides system policy, execution assessment, signature, revocation, and extension policy services.",
      disableConsequence: "System policy validation and several application trust decisions will no longer be available.",
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
      requiresSIPDisabledToDisable: true
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
