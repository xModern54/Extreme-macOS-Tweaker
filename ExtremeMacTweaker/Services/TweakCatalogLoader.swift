import CryptoKit
import Foundation

enum TweakCatalogRuntimePolicy {
  // Disabled during active catalog development for fast external JSON iteration.
  static let semanticValidationEnabled = false
  static let integrityValidationEnabled = false
}

enum TweakCatalogSeal {
  // A generated SHA-256 value will be placed here when catalog sealing is enabled.
  static let expectedSHA256: String? = nil
}

enum TweakCatalogLoadingError: LocalizedError {
  case bundledCatalogMissing
  case semanticValidation([TweakCatalogValidationIssue])
  case integrityMismatch(expected: String, actual: String)

  var errorDescription: String? {
    switch self {
    case .bundledCatalogMissing:
      "TweakCatalog.json is missing from the application bundle."
    case .semanticValidation(let issues):
      issues.map(\.message).joined(separator: "\n")
    case .integrityMismatch(let expected, let actual):
      "Catalog integrity check failed. Expected \(expected), received \(actual)."
    }
  }
}

struct LoadedTweakCatalog: Sendable {
  enum Source: Sendable {
    case bundled
    case external(URL)
  }

  let catalog: TweakCatalog
  let source: Source
  let sha256: String
}

struct TweakCatalogLoader: Sendable {
  static let externalCatalogURL = FileManager.default.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
  )[0]
  .appendingPathComponent("Tweaker", isDirectory: true)
  .appendingPathComponent("TweakCatalog.json")

  func load() throws -> LoadedTweakCatalog {
    let source: LoadedTweakCatalog.Source
    let url: URL

    if FileManager.default.fileExists(atPath: Self.externalCatalogURL.path) {
      url = Self.externalCatalogURL
      source = .external(url)
    } else {
      guard let bundledURL = Bundle.main.url(forResource: "TweakCatalog", withExtension: "json") else {
        throw TweakCatalogLoadingError.bundledCatalogMissing
      }
      url = bundledURL
      source = .bundled
    }

    let data = try Data(contentsOf: url)
    let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()

    if TweakCatalogRuntimePolicy.integrityValidationEnabled,
       let expectedHash = TweakCatalogSeal.expectedSHA256,
       expectedHash != hash {
      throw TweakCatalogLoadingError.integrityMismatch(expected: expectedHash, actual: hash)
    }

    let catalog = try JSONDecoder().decode(TweakCatalog.self, from: data)
    if TweakCatalogRuntimePolicy.semanticValidationEnabled {
      let issues = TweakCatalogValidator.validate(catalog)
      if !issues.isEmpty {
        throw TweakCatalogLoadingError.semanticValidation(issues)
      }
    }

    return LoadedTweakCatalog(catalog: catalog, source: source, sha256: hash)
  }

  func externalSignature() -> String {
    let url = Self.externalCatalogURL
    guard
      let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
      let modificationDate = values.contentModificationDate,
      let fileSize = values.fileSize
    else {
      return "bundled"
    }
    return "\(modificationDate.timeIntervalSince1970):\(fileSize)"
  }
}
