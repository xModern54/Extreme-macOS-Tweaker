import Foundation

struct TweakCatalogValidationIssue: Error, Identifiable, Sendable {
  let id: String
  let message: String
}

enum TweakCatalogValidator {
  static func validate(_ catalog: TweakCatalog) -> [TweakCatalogValidationIssue] {
    var issues: [TweakCatalogValidationIssue] = []

    if catalog.schemaVersion != 1 {
      issues.append(issue("schema-version", "Unsupported catalog schema version \(catalog.schemaVersion)."))
    }
    if catalog.compatibility.minimumMacOSMajor > catalog.compatibility.maximumMacOSMajor {
      issues.append(issue("compatibility-range", "The minimum macOS version exceeds the maximum version."))
    }
    if catalog.compatibility.architectures.isEmpty {
      issues.append(issue("architectures", "The catalog must support at least one architecture."))
    }

    appendDuplicateIssues(catalog.categories.map(\.id), type: "category", to: &issues)
    appendDuplicateIssues(catalog.services.map(\.id), type: "service", to: &issues)
    appendDuplicateIssues(catalog.serviceGroups.map(\.id), type: "service group", to: &issues)
    appendDuplicateIssues(catalog.features.map(\.id), type: "feature", to: &issues)

    let categoryIDs = Set(catalog.categories.map(\.id))
    let serviceIDs = Set(catalog.services.map(\.id))
    let serviceGroupIDs = Set(catalog.serviceGroups.map(\.id))

    for group in catalog.serviceGroups {
      for serviceID in group.services where !serviceIDs.contains(serviceID) {
        issues.append(
          issue(
            "group-\(group.id)-service-\(serviceID)",
            "Service group \(group.id) references unknown service \(serviceID)."
          )
        )
      }
    }

    for feature in catalog.features {
      if !categoryIDs.contains(feature.categoryID) {
        issues.append(
          issue(
            "feature-\(feature.id)-category",
            "Feature \(feature.id) references unknown category \(feature.categoryID)."
          )
        )
      }
      for groupID in feature.disableServiceGroups where !serviceGroupIDs.contains(groupID) {
        issues.append(
          issue(
            "feature-\(feature.id)-group-\(groupID)",
            "Feature \(feature.id) references unknown service group \(groupID)."
          )
        )
      }
      if feature.impact.estimatedMemoryMB < 0 || feature.impact.estimatedProcessReduction < 0 {
        issues.append(
          issue(
            "feature-\(feature.id)-impact",
            "Feature \(feature.id) contains a negative impact estimate."
          )
        )
      }
    }

    return issues
  }

  private static func appendDuplicateIssues(
    _ ids: [String],
    type: String,
    to issues: inout [TweakCatalogValidationIssue]
  ) {
    let grouped = Dictionary(grouping: ids, by: { $0 })
    for (id, matches) in grouped where matches.count > 1 {
      issues.append(issue("duplicate-\(type)-\(id)", "Duplicate \(type) ID: \(id)."))
    }
  }

  private static func issue(_ id: String, _ message: String) -> TweakCatalogValidationIssue {
    TweakCatalogValidationIssue(id: id, message: message)
  }
}
