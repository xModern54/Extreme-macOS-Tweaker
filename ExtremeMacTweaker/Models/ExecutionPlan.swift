import Foundation

struct ExecutionPlan: Sendable {
  let changes: [OptimizationChange]
  let steps: [ExecutionStep]

  var requiresPrivileges: Bool { !steps.isEmpty }
  var requiresReboot: Bool {
    steps.contains { step in
      if case .createSystemSnapshot = step { return true }
      return false
    }
  }
}

enum ExecutionStep: Identifiable, Sendable {
  case verifySystemRequirements
  case mountSystemVolume
  case disableSystemApplication(sourcePath: String, destinationPath: String)
  case restoreSystemApplication(sourcePath: String, destinationPath: String)
  case deleteSystemApplication(path: String)
  case setLaunchService(id: String, enabled: Bool)
  case setSecurityFeature(id: String, enabled: Bool)
  case createSystemSnapshot

  var id: String { description }

  var description: String {
    switch self {
    case .verifySystemRequirements:
      "Verify system requirements"
    case .mountSystemVolume:
      "Mount the system volume for writing"
    case .disableSystemApplication(let source, _):
      "Disable \(URL(fileURLWithPath: source).deletingPathExtension().lastPathComponent)"
    case .restoreSystemApplication(let source, _):
      "Restore \(URL(fileURLWithPath: source).deletingPathExtension().lastPathComponent)"
    case .deleteSystemApplication(let path):
      "Delete \(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)"
    case .setLaunchService(let id, let enabled):
      "\(enabled ? "Enable" : "Disable") service \(id)"
    case .setSecurityFeature(let id, let enabled):
      "\(enabled ? "Enable" : "Disable") security feature \(id)"
    case .createSystemSnapshot:
      "Create a new bootable system snapshot"
    }
  }
}
