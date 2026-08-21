import Foundation

enum CleanSweepLayout {
  static let root = "/System/Library/CleanSweep"
  static let launchDaemonsDirectory = "/System/Library/LaunchDaemons"
  static let launchAgentsDirectory = "/System/Library/LaunchAgents"
  static let systemLibraryPrefix = "/System/Library/"

  static func isSweepable(_ path: String) -> Bool {
    isSweepablePlist(path) || isSweepableXPC(path)
  }

  static func isSweepablePlist(_ path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard url.pathExtension.caseInsensitiveCompare("plist") == .orderedSame else {
      return false
    }
    let parent = url.deletingLastPathComponent().path
    return parent == launchDaemonsDirectory || parent == launchAgentsDirectory
  }

  static func isSweepableXPC(_ path: String) -> Bool {
    let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
    let url = URL(fileURLWithPath: standardized)
    guard
      url.pathExtension.caseInsensitiveCompare("xpc") == .orderedSame,
      standardized.hasPrefix(systemLibraryPrefix),
      url.deletingLastPathComponent().lastPathComponent == "XPCServices"
    else {
      return false
    }
    return true
  }

  static func hiddenPath(for sourcePath: String) -> String? {
    let standardized = URL(fileURLWithPath: sourcePath).standardizedFileURL.path
    if isSweepablePlist(standardized) {
      let url = URL(fileURLWithPath: standardized)
      let folder = url.deletingLastPathComponent().lastPathComponent
      return "\(root)/\(folder)/\(url.lastPathComponent)"
    }
    if isSweepableXPC(standardized) {
      let suffix = String(standardized.dropFirst("/System".count))
      return root + suffix
    }
    return nil
  }
}
