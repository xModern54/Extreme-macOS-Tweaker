import Foundation

enum CleanSweepLayout {
  static let root = CleanSweepPathPolicy.root
  static let launchDaemonsDirectory = CleanSweepPathPolicy.launchDaemonsDirectory
  static let launchAgentsDirectory = CleanSweepPathPolicy.launchAgentsDirectory
  static let systemLibraryPrefix = CleanSweepPathPolicy.systemLibraryPrefix

  static func isSweepable(_ path: String) -> Bool {
    CleanSweepPathPolicy.isLiveSweepPath(path)
  }

  static func hiddenPath(for sourcePath: String) -> String? {
    CleanSweepPathPolicy.hiddenPath(for: sourcePath)
  }
}
