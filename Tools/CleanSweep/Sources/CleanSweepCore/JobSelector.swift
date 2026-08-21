import Foundation

public enum JobSelector: Equatable, CustomStringConvertible {
  case label(String)
  case cacheKey(String)

  public var description: String {
    switch self {
    case .label(let label):
      "label \(label)"
    case .cacheKey(let key):
      "cache key \(key)"
    }
  }
}

public struct CacheJob: Equatable {
  public let cacheKey: String
  public let label: String
  public let entry: NSDictionary

  public init(cacheKey: String, label: String, entry: NSDictionary) {
    self.cacheKey = cacheKey
    self.label = label
    self.entry = entry
  }

  public static func == (lhs: CacheJob, rhs: CacheJob) -> Bool {
    lhs.cacheKey == rhs.cacheKey
      && lhs.label == rhs.label
      && lhs.entry.isEqual(rhs.entry)
  }
}
