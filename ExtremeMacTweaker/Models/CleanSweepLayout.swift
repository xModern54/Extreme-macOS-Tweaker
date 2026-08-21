import Foundation

enum CleanSweepLayout {
  static let root = "/System/Library/CleanSweep"
  static let launchDaemonsDirectory = "/System/Library/LaunchDaemons"
  static let launchAgentsDirectory = "/System/Library/LaunchAgents"

  static func isSweepable(_ path: String) -> Bool {
    let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
    return parent == launchDaemonsDirectory || parent == launchAgentsDirectory
  }

  static func hiddenPath(for sourcePath: String) -> String? {
    guard isSweepable(sourcePath) else { return nil }
    let url = URL(fileURLWithPath: sourcePath)
    let folder = url.deletingLastPathComponent().lastPathComponent
    return "\(root)/\(folder)/\(url.lastPathComponent)"
  }
}
