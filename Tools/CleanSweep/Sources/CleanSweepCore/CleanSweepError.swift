import Foundation

public enum CleanSweepError: Error, Equatable, CustomStringConvertible {
  case invalidCache(String)
  case invalidStash(String)
  case jobNotFound(String)
  case forbiddenLabel(String)
  case restoreCollision(String)
  case invalidSelector(String)

  public var description: String {
    switch self {
    case .invalidCache(let message):
      "Invalid launchd cache: \(message)"
    case .invalidStash(let message):
      "Invalid Clean Sweep stash: \(message)"
    case .jobNotFound(let selector):
      "No launchd cache job matched \(selector)."
    case .forbiddenLabel(let label):
      "Refusing to modify protected launchd job \(label)."
    case .restoreCollision(let cacheKey):
      "Cache already contains a job at \(cacheKey)."
    case .invalidSelector(let message):
      message
    }
  }
}
