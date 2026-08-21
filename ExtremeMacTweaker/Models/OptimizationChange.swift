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
  let sizeInBytes: Int64

  private enum CodingKeys: String, CodingKey {
    case applicationID, name, sourcePath, action, sizeInBytes
  }

  init(
    applicationID: String,
    name: String,
    sourcePath: String,
    action: SystemApplicationAction,
    sizeInBytes: Int64 = 0
  ) {
    self.applicationID = applicationID
    self.name = name
    self.sourcePath = sourcePath
    self.action = action
    self.sizeInBytes = sizeInBytes
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    applicationID = try container.decode(String.self, forKey: .applicationID)
    name = try container.decode(String.self, forKey: .name)
    sourcePath = try container.decode(String.self, forKey: .sourcePath)
    action = try container.decode(SystemApplicationAction.self, forKey: .action)
    sizeInBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeInBytes) ?? 0
  }
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
  let plistPath: String?

  private enum CodingKeys: String, CodingKey {
    case serviceID, label, domain, featureID, featureTitle, action, plistPath
  }

  init(
    serviceID: String,
    label: String,
    domain: TweakCatalogService.Domain,
    featureID: String?,
    featureTitle: String?,
    action: Action,
    plistPath: String? = nil
  ) {
    self.serviceID = serviceID
    self.label = label
    self.domain = domain
    self.featureID = featureID
    self.featureTitle = featureTitle
    self.action = action
    self.plistPath = plistPath
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    serviceID = try container.decode(String.self, forKey: .serviceID)
    label = try container.decode(String.self, forKey: .label)
    domain = try container.decode(TweakCatalogService.Domain.self, forKey: .domain)
    featureID = try container.decodeIfPresent(String.self, forKey: .featureID)
    featureTitle = try container.decodeIfPresent(String.self, forKey: .featureTitle)
    action = try container.decode(Action.self, forKey: .action)
    plistPath = try container.decodeIfPresent(String.self, forKey: .plistPath)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(serviceID, forKey: .serviceID)
    try container.encode(label, forKey: .label)
    try container.encode(domain, forKey: .domain)
    try container.encodeIfPresent(featureID, forKey: .featureID)
    try container.encodeIfPresent(featureTitle, forKey: .featureTitle)
    try container.encode(action, forKey: .action)
    try container.encodeIfPresent(plistPath, forKey: .plistPath)
  }
}

struct SecurityFeatureChange: Codable, Hashable, Sendable {
  enum Action: String, Codable, Sendable {
    case enable
    case disable
  }

  let featureID: String
  let action: Action
}

struct SystemComponentChange: Codable, Hashable, Sendable {
  let componentID: String
  let title: String
  let sizeInBytes: Int64

  private enum CodingKeys: String, CodingKey {
    case componentID, title, sizeInBytes
  }

  init(componentID: String, title: String, sizeInBytes: Int64 = 0) {
    self.componentID = componentID
    self.title = title
    self.sizeInBytes = sizeInBytes
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    componentID = try container.decode(String.self, forKey: .componentID)
    title = try container.decode(String.self, forKey: .title)
    sizeInBytes = try container.decodeIfPresent(Int64.self, forKey: .sizeInBytes) ?? 0
  }
}

enum OptimizationChange: Codable, Hashable, Identifiable, Sendable {
  case systemApplication(SystemApplicationChange)
  case launchService(LaunchServiceChange)
  case securityFeature(SecurityFeatureChange)
  case systemComponent(SystemComponentChange)

  var id: String {
    switch self {
    case .systemApplication(let change): "system-app:\(change.applicationID)"
    case .launchService(let change): "launch-service:\(change.serviceID)"
    case .securityFeature(let change): "security-feature:\(change.featureID)"
    case .systemComponent(let change): "system-component:\(change.componentID)"
    }
  }

  var title: String {
    switch self {
    case .systemApplication(let change):
      "\(change.action.title) \(change.name)"
    case .launchService(let change):
      "\(change.action == .enable ? "Enable" : "Disable") \(change.label)"
    case .securityFeature(let change):
      securityFeatureTitle(change)
    case .systemComponent(let change):
      "Remove \(change.title)"
    }
  }
}

private func securityFeatureTitle(_ change: SecurityFeatureChange) -> String {
  let title = SecurityProtectionCatalog.protection(withID: change.featureID)?.title
    ?? change.featureID
  if change.featureID == "download-whitelist" {
    return change.action == .enable ? title : "Turn off \(title)"
  }
  return change.action == .disable ? title : "Turn off \(title)"
}
