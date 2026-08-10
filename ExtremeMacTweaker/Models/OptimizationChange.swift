import Foundation

enum SystemApplicationState: String, Codable, Sendable {
  case installed
  case disabled
}

enum SystemApplicationAction: String, Codable, Sendable {
  case disable
  case restore
  case delete

  var title: String {
    switch self {
    case .disable: "Disable"
    case .restore: "Restore"
    case .delete: "Delete"
    }
  }

  var systemImage: String {
    switch self {
    case .disable: "nosign"
    case .restore: "arrow.uturn.backward.circle"
    case .delete: "trash"
    }
  }
}

struct SystemApplicationChange: Codable, Hashable, Sendable {
  let applicationID: String
  let name: String
  let sourcePath: String
  let action: SystemApplicationAction
}

struct LaunchServiceChange: Codable, Hashable, Sendable {
  enum Action: String, Codable, Sendable {
    case enable
    case disable
  }

  let serviceID: String
  let label: String
  let domain: TweakCatalogService.Domain
  let featureID: String?
  let featureTitle: String?
  let action: Action
}

struct SecurityFeatureChange: Codable, Hashable, Sendable {
  enum Action: String, Codable, Sendable {
    case enable
    case disable
  }

  let featureID: String
  let action: Action
}

enum OptimizationChange: Codable, Hashable, Identifiable, Sendable {
  case systemApplication(SystemApplicationChange)
  case launchService(LaunchServiceChange)
  case securityFeature(SecurityFeatureChange)

  var id: String {
    switch self {
    case .systemApplication(let change): "system-app:\(change.applicationID)"
    case .launchService(let change): "launch-service:\(change.serviceID)"
    case .securityFeature(let change): "security-feature:\(change.featureID)"
    }
  }

  var title: String {
    switch self {
    case .systemApplication(let change):
      "\(change.action.title) \(change.name)"
    case .launchService(let change):
      "\(change.action == .enable ? "Enable" : "Disable") \(change.label)"
    case .securityFeature(let change):
      "\(change.action == .enable ? "Enable" : "Disable") \(change.featureID)"
    }
  }
}
