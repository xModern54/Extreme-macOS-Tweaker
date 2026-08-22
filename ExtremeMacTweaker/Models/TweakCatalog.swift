import Foundation

enum LaunchServiceDisableMethod: String, Codable, Hashable, Sendable {
  case launchctl
  case cleanSweep
}

struct TweakCatalog: Decodable, Sendable {
  let schemaVersion: Int
  let catalogVersion: String
  let serviceDisablePolicy: LaunchServiceDisableMethod
  let compatibility: TweakCatalogCompatibility
  let categories: [TweakCatalogCategory]
  let services: [TweakCatalogService]
  let serviceGroups: [TweakCatalogServiceGroup]
  let features: [TweakCatalogFeature]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case catalogVersion
    case serviceDisablePolicy
    case compatibility
    case categories
    case services
    case serviceGroups
    case features
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
    catalogVersion = try container.decode(String.self, forKey: .catalogVersion)
    serviceDisablePolicy = try container.decodeIfPresent(
      LaunchServiceDisableMethod.self,
      forKey: .serviceDisablePolicy
    ) ?? .launchctl
    compatibility = try container.decode(TweakCatalogCompatibility.self, forKey: .compatibility)
    categories = try container.decode([TweakCatalogCategory].self, forKey: .categories)
    services = try container.decode([TweakCatalogService].self, forKey: .services)
    serviceGroups = try container.decode([TweakCatalogServiceGroup].self, forKey: .serviceGroups)
    features = try container.decode([TweakCatalogFeature].self, forKey: .features)
  }

  func disableMethod(for service: TweakCatalogService) -> LaunchServiceDisableMethod {
    service.disableMethod ?? serviceDisablePolicy
  }
}

struct TweakCatalogCompatibility: Decodable, Sendable {
  let minimumMacOSMajor: Int
  let maximumMacOSMajor: Int
  let architectures: [String]
}

struct TweakCatalogCategory: Decodable, Identifiable, Sendable {
  let id: String
  let title: String
  let systemImage: String
  let order: Int

  var localizedTitle: String {
    CatalogLocalization.string(
      key: "category.\(id).title",
      fallback: title
    )
  }
}

struct TweakCatalogService: Decodable, Identifiable, Sendable {
  enum Domain: String, Codable, Hashable, Sendable {
    case system
    case user
    case gui
  }

  enum Kind: String, Decodable, Equatable, Sendable {
    case daemon
    case agent
    case xpcService
  }

  let id: String
  let label: String
  let domain: Domain
  let kind: Kind
  let plistPath: String?
  let assetPath: String?
  let disableMethod: LaunchServiceDisableMethod?

  var sweepPaths: [String] {
    [plistPath, assetPath].compactMap { $0 }
  }
}

struct TweakCatalogServiceGroup: Decodable, Identifiable, Sendable {
  let id: String
  let services: [String]
}

struct TweakCatalogFeature: Decodable, Identifiable, Sendable {
  let id: String
  let categoryID: String
  let title: String
  let question: String
  let description: String
  let disableGuidance: String
  let systemImage: String
  let defaultEnabled: Bool
  let disableServiceGroups: [String]
  let impact: TweakCatalogImpact
  let order: Int

  var localizedTitle: String {
    localized(field: "title", fallback: title)
  }

  var localizedQuestion: String {
    localized(field: "question", fallback: question)
  }

  var localizedDescription: String {
    localized(field: "description", fallback: description)
  }

  var localizedDisableGuidance: String {
    localized(field: "disableGuidance", fallback: disableGuidance)
  }

  private func localized(field: String, fallback: String) -> String {
    CatalogLocalization.string(
      key: "tweak.\(id).\(field)",
      fallback: fallback
    )
  }
}

struct TweakCatalogImpact: Decodable, Sendable {
  let estimatedMemoryMB: Int
  let estimatedProcessReduction: Int
}

private enum CatalogLocalization {
  static func string(key: String, fallback: String) -> String {
    Bundle.main.localizedString(
      forKey: key,
      value: fallback,
      table: "TweakCatalog"
    )
  }
}
