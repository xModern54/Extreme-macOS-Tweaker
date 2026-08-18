import Foundation

struct ExecutionPlan: Sendable {
  let changes: [OptimizationChange]
  let steps: [ExecutionStep]

  var requiresPrivileges: Bool { !steps.isEmpty }
  var requiresSystemIntegrityProtectionDisabled: Bool {
    changes.contains { change in
      switch change {
      case .systemApplication:
        true
      case .launchService(let service):
        service.action == .disable
      case .securityFeature(let feature):
        if feature.featureID == "system-policy" || feature.featureID == "download-whitelist" {
          true
        } else {
          feature.action == .disable
            && (SecurityProtectionCatalog.protection(withID: feature.featureID)?
              .requiresSIPDisabledToDisable ?? true)
        }
      case .systemComponent:
        true
      }
    }
  }
  var requiresAuthenticatedRootDisabled: Bool {
    changes.contains { change in
      switch change {
      case .systemApplication:
        true
      case .securityFeature(let feature):
        feature.featureID == "download-whitelist"
      default:
        false
      }
    }
  }
  var requiresSystemProtectionCheck: Bool {
    requiresSystemIntegrityProtectionDisabled || requiresAuthenticatedRootDisabled
  }
  var requiresReboot: Bool {
    steps.contains { step in
      if case .createSystemSnapshot = step { return true }
      return false
    }
  }
}

enum ExecutionStep: Identifiable, Sendable {
  case verifySystemRequirements
  case verifySystemIntegrityProtection
  case mountSystemVolume
  case disableSystemApplication(sourcePath: String, destinationPath: String)
  case restoreSystemApplication(sourcePath: String, destinationPath: String)
  case deleteSystemApplication(path: String)
  case relocateDisabledApplications
  case setLaunchService(
    id: String,
    label: String,
    domain: TweakCatalogService.Domain,
    enabled: Bool
  )
  case setSecurityFeature(id: String, enabled: Bool)
  case installSystemDequarantineDaemon(downloadsPath: String)
  case removeSystemDequarantineDaemon
  case removeSystemComponent(id: String, title: String)
  case createSystemSnapshot
  case unmountSystemVolume

  var id: String { description }

  var description: String {
    switch self {
    case .verifySystemRequirements:
      "Verify system requirements"
    case .verifySystemIntegrityProtection:
      "Verify System Integrity Protection is disabled"
    case .mountSystemVolume:
      "Mount the system volume for writing"
    case .disableSystemApplication(let source, _):
      "Disable \(URL(fileURLWithPath: source).deletingPathExtension().lastPathComponent)"
    case .restoreSystemApplication(let source, _):
      "Restore \(URL(fileURLWithPath: source).deletingPathExtension().lastPathComponent)"
    case .deleteSystemApplication(let path):
      "Delete \(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)"
    case .relocateDisabledApplications:
      "Move hidden applications out of Launch Services"
    case .setLaunchService(_, let label, _, let enabled):
      "\(enabled ? "Enabling" : "Disabling") service \(label)"
    case .setSecurityFeature(let id, let enabled):
      enabled
        ? "Turn off \(SecurityProtectionCatalog.protection(withID: id)?.title ?? id)"
        : (SecurityProtectionCatalog.protection(withID: id)?.title ?? id)
    case .installSystemDequarantineDaemon:
      "Install the system dequarantine daemon"
    case .removeSystemDequarantineDaemon:
      "Remove the system dequarantine daemon"
    case .removeSystemComponent(_, let title):
      "Remove \(title)"
    case .createSystemSnapshot:
      "Create a new bootable system snapshot"
    case .unmountSystemVolume:
      "Unmount the writable system volume"
    }
  }
}
