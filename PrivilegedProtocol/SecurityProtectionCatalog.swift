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
  let applyGuidance: String
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
      applyGuidance: "Apply this if you regularly open unsigned or unnotarized apps and do not want macOS to block them. Leave it off if you still want Apple's developer-signature and notarization checks.",
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
      applyGuidance: "Apply this if you do not want Apple's built-in malware scanner running in the background. Leave it off if you still want XProtect to scan for and remove known malware.",
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
      applyGuidance: "Apply this if you do not want \"Are you sure you want to open this app?\" prompts. This also turns on Global Item Whitelist. Leave it off if you still want those prompts.",
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
      question: "Treat every file that lands in Downloads as fully trusted?",
      summary: "Installs a system LaunchDaemon that strips the quarantine flag from files in Downloads as soon as they appear.",
      disableConsequence: "Built-in antivirus, Gatekeeper, and quarantine checks no longer apply to files that land in Downloads. Every file that arrives is treated as fully trusted and can launch like a normal local item. A system LaunchDaemon is written to the signed system volume and starts at boot with launchd. A restart is required.",
      applyGuidance: "Apply this if you want every download to be trusted automatically, with no quarantine prompt and no extra scan. Leave it off if you still want macOS to mark new files as untrusted until you open them yourself.",
      systemImage: "tray.and.arrow.down",
      kind: .dequarantine,
      services: [],
      requiresSIPDisabledToDisable: true,
      confirmsBeforeDisable: true
    ),
    SecurityProtection(
      id: "user-autostarts",
      title: "Disable Any Autostarts",
      question: "Turn off user-space software autostarts?",
      summary: "Shuts down Background Task Management, the user-space subsystem that loads third-party LaunchAgents and login items.",
      disableConsequence: "Fully disables the user-space autostart system. Other apps cannot add custom launch agents, and existing user-space launch agents will stop starting.",
      applyGuidance: "Apply this only when you do not need third-party autostarts and do not want other software adding LaunchAgents. Leave it off if you use apps that must start in the background.",
      systemImage: "powerplug",
      kind: .launchServices,
      services: [
        service(
          "backgroundtaskmanagementd",
          "com.apple.backgroundtaskmanagementd",
          .system,
          "/System/Library/LaunchDaemons/com.apple.backgroundtaskmanagementd.plist"
        ),
        service(
          "backgroundtaskmanagement-agent",
          "com.apple.backgroundtaskmanagement.agent",
          .gui,
          "/System/Library/LaunchAgents/com.apple.backgroundtaskmanagement.agent.plist"
        ),
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
