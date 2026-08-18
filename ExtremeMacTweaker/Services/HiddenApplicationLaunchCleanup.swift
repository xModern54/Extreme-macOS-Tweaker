import Foundation

enum HiddenApplicationLaunchCleanup {
  private static let hiddenPathMarkers = [
    "/System/Library/TweakerDisabledApplications/",
    "/System/Applications/.disabled/",
  ]

  static func retract(applications: [SystemApplication]) {
    let hidden = applications.filter { $0.state == .disabled }
    guard !hidden.isEmpty else { return }

    unregisterFromLaunchServices(paths: hidden.map(\.url.path))
    removeDockTiles(
      paths: hidden.map(\.url.path),
      bundleIdentifiers: Set(hidden.compactMap(\.bundleIdentifier))
    )
  }

  private static func unregisterFromLaunchServices(paths: [String]) {
    let lsregister = URL(
      fileURLWithPath:
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    )
    guard FileManager.default.isExecutableFile(atPath: lsregister.path) else { return }

    for path in paths {
      let process = Process()
      process.executableURL = lsregister
      process.arguments = ["-u", path]
      process.standardOutput = FileHandle.nullDevice
      process.standardError = FileHandle.nullDevice
      try? process.run()
      process.waitUntilExit()
    }
  }

  private static func removeDockTiles(paths: [String], bundleIdentifiers: Set<String>) {
    guard let defaults = UserDefaults(suiteName: "com.apple.dock") else { return }

    var changed = false
    for key in ["persistent-apps", "persistent-others"] {
      guard let tiles = defaults.array(forKey: key) as? [[String: Any]] else { continue }
      let filtered = tiles.filter { tile in
        !tilePointsToHiddenApplication(
          tile,
          paths: paths,
          bundleIdentifiers: bundleIdentifiers
        )
      }
      if filtered.count != tiles.count {
        defaults.set(filtered, forKey: key)
        changed = true
      }
    }

    guard changed else { return }
    defaults.synchronize()
    restartDock()
  }

  private static func tilePointsToHiddenApplication(
    _ tile: [String: Any],
    paths: [String],
    bundleIdentifiers: Set<String>
  ) -> Bool {
    guard let tileData = tile["tile-data"] as? [String: Any] else { return false }

    if let bundleID = tileData["bundle-identifier"] as? String,
      bundleIdentifiers.contains(bundleID)
    {
      return true
    }

    let urlString = dockURLString(in: tileData)
    guard let urlString else { return false }

    if hiddenPathMarkers.contains(where: { urlString.contains($0) }) {
      return true
    }

    return paths.contains { path in
      urlString.contains(path) || urlString.contains(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)
    }
  }

  private static func dockURLString(in tileData: [String: Any]) -> String? {
    if let fileData = tileData["file-data"] as? [String: Any],
      let urlString = fileData["_CFURLString"] as? String
    {
      return urlString
    }
    return tileData["file-label"] as? String
  }

  private static func restartDock() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
    process.arguments = ["Dock"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
  }
}
