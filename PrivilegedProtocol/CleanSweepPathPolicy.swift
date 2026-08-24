import Foundation

enum CleanSweepPathPolicy {
  static let root = "/System/Library/CleanSweep"
  static let launchDaemonsDirectory = "/System/Library/LaunchDaemons"
  static let launchAgentsDirectory = "/System/Library/LaunchAgents"
  static let hiddenLaunchDaemonsDirectory = root + "/LaunchDaemons"
  static let hiddenLaunchAgentsDirectory = root + "/LaunchAgents"
  static let systemLibraryPrefix = "/System/Library/"
  static let hiddenLibraryPrefix = root + "/Library/"

  static func isLiveSweepPath(_ path: String) -> Bool {
    isLivePlist(path) || isLiveXPC(path) || isLiveFrameworkSupport(path)
  }

  static func isAllowedSweepPath(_ path: String) -> Bool {
    isLivePlist(path)
      || isHiddenPlist(path)
      || isLiveXPC(path)
      || isHiddenXPC(path)
      || isLiveFrameworkSupport(path)
      || isHiddenFrameworkSupport(path)
  }

  static func hiddenPath(for sourcePath: String) -> String? {
    let standardized = standardizedPath(sourcePath)
    if isLivePlist(standardized) {
      let url = URL(fileURLWithPath: standardized)
      let folder = url.deletingLastPathComponent().lastPathComponent
      return "\(root)/\(folder)/\(url.lastPathComponent)"
    }
    if isLiveXPC(standardized) || isLiveFrameworkSupport(standardized) {
      let suffix = String(standardized.dropFirst("/System".count))
      return root + suffix
    }
    return nil
  }

  private static func isLivePlist(_ path: String) -> Bool {
    isPlist(in: path, parents: [launchDaemonsDirectory, launchAgentsDirectory])
  }

  private static func isHiddenPlist(_ path: String) -> Bool {
    isPlist(in: path, parents: [hiddenLaunchDaemonsDirectory, hiddenLaunchAgentsDirectory])
  }

  private static func isLiveXPC(_ path: String) -> Bool {
    guard isXPCBundle(path) else { return false }
    let standardized = standardizedPath(path)
    return standardized.hasPrefix(systemLibraryPrefix)
      && !standardized.hasPrefix(root + "/")
  }

  private static func isHiddenXPC(_ path: String) -> Bool {
    guard isXPCBundle(path) else { return false }
    return standardizedPath(path).hasPrefix(hiddenLibraryPrefix)
  }

  private static func isLiveFrameworkSupport(_ path: String) -> Bool {
    frameworkSupportRelativePath(path) != nil
      && standardizedPath(path).hasPrefix(systemLibraryPrefix)
      && !standardizedPath(path).hasPrefix(root + "/")
  }

  private static func isHiddenFrameworkSupport(_ path: String) -> Bool {
    let standardized = standardizedPath(path)
    guard standardized.hasPrefix(hiddenLibraryPrefix) else { return false }
    let reconstructed = "/System" + String(standardized.dropFirst(root.count))
    return frameworkSupportRelativePath(reconstructed) != nil
  }

  private static func isPlist(in path: String, parents: [String]) -> Bool {
    let url = URL(fileURLWithPath: standardizedPath(path))
    guard url.pathExtension.caseInsensitiveCompare("plist") == .orderedSame else {
      return false
    }
    return parents.contains(url.deletingLastPathComponent().path)
  }

  private static func isXPCBundle(_ path: String) -> Bool {
    let url = URL(fileURLWithPath: standardizedPath(path))
    return url.pathExtension.caseInsensitiveCompare("xpc") == .orderedSame
      && url.deletingLastPathComponent().lastPathComponent == "XPCServices"
  }

  /// `PrivateFrameworks/SessionCore.framework/Support/liveactivitiesd` or Frameworks equivalent.
  private static func frameworkSupportRelativePath(_ path: String) -> String? {
    let standardized = standardizedPath(path)
    let url = URL(fileURLWithPath: standardized)
    let name = url.lastPathComponent
    guard !name.isEmpty, name != ".", name != "..", !name.contains("/") else {
      return nil
    }
    let support = url.deletingLastPathComponent()
    guard support.lastPathComponent == "Support" else { return nil }
    let framework = support.deletingLastPathComponent()
    guard framework.pathExtension.caseInsensitiveCompare("framework") == .orderedSame else {
      return nil
    }
    let collection = framework.deletingLastPathComponent().lastPathComponent
    guard collection == "PrivateFrameworks" || collection == "Frameworks" else {
      return nil
    }
    return "\(collection)/\(framework.lastPathComponent)/Support/\(name)"
  }

  private static func standardizedPath(_ path: String) -> String {
    URL(fileURLWithPath: path).standardizedFileURL.path
  }
}
