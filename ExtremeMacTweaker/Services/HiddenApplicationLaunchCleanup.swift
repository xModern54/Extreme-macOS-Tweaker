import Foundation

enum HiddenApplicationLaunchCleanup {
  private static let hiddenPathMarkers = [
    "/System/Library/TweakerDisabledApplications/",
    "/System/Applications/.disabled/",
  ]
  private static let dockListKeys = [
    "persistent-apps",
    "persistent-others",
    "recent-apps",
  ]

  struct Target: Codable, Hashable, Sendable {
    var path: String
    var bundleIdentifier: String?
    var name: String?
  }

  static func retract(applications: [SystemApplication]) {
    let hidden = applications.filter { $0.state == .disabled }
    let hiddenTargets = hidden.map {
      Target(path: $0.url.path, bundleIdentifier: $0.bundleIdentifier, name: $0.name)
    }
    if !hidden.isEmpty {
      unregisterFromLaunchServices(paths: hidden.map(\.url.path))
    }

    let targets = uniqued(hiddenTargets + loadPersistedTargets())
    guard !targets.isEmpty else { return }
    removeDockTiles(targets: targets)
  }

  static func retract(changes: [SystemApplicationChange]) {
    let restored = changes.filter { $0.action == .restore }
    if !restored.isEmpty {
      forget(changes: restored)
    }

    let retractable = changes.filter { $0.action == .disable || $0.action == .delete }
    guard !retractable.isEmpty else { return }

    let targets = retractable.map(target(from:))
    let deleted = retractable.filter { $0.action == .delete }
    if !deleted.isEmpty {
      persist(merging: deleted.map(target(from:)))
    }
    removeDockTiles(targets: targets)
  }

  private static func target(from change: SystemApplicationChange) -> Target {
    let bundleIdentifier =
      change.bundleIdentifier
      ?? Bundle(url: URL(fileURLWithPath: change.sourcePath))?.bundleIdentifier
    return Target(
      path: change.sourcePath,
      bundleIdentifier: bundleIdentifier,
      name: change.name
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

  private static func removeDockTiles(targets: [Target]) {
    guard !targets.isEmpty, let defaults = UserDefaults(suiteName: "com.apple.dock") else {
      return
    }

    var filteredByKey: [String: [[String: Any]]] = [:]
    for key in dockListKeys {
      guard let tiles = defaults.array(forKey: key) as? [[String: Any]] else { continue }
      let filtered = tiles.filter { tile in
        !tileMatches(tile, targets: targets)
      }
      if filtered.count != tiles.count {
        filteredByKey[key] = filtered
      }
    }

    guard !filteredByKey.isEmpty else { return }

    // Freeze Dock before writing so it cannot persist in-memory tiles over the edit.
    run("/usr/bin/killall", ["-STOP", "Dock"])
    for (key, tiles) in filteredByKey {
      defaults.set(tiles, forKey: key)
    }
    defaults.set(defaults.integer(forKey: "mod-count") + 1, forKey: "mod-count")
    defaults.synchronize()
    run("/usr/bin/killall", ["-KILL", "Dock"])
  }

  private static func tileMatches(_ tile: [String: Any], targets: [Target]) -> Bool {
    guard let tileData = tile["tile-data"] as? [String: Any] else { return false }

    if let bundleID = tileData["bundle-identifier"] as? String,
      targets.contains(where: { $0.bundleIdentifier == bundleID })
    {
      return true
    }

    if let urlString = dockURLString(in: tileData) {
      if hiddenPathMarkers.contains(where: { urlString.contains($0) }) {
        return true
      }
      if targets.contains(where: { urlPointsTo($0.path, urlString: urlString) }) {
        return true
      }
    }

    if let fileLabel = tileData["file-label"] as? String {
      return targets.contains { target in
        labelMatches(fileLabel, target: target)
      }
    }

    return false
  }

  private static func urlPointsTo(_ path: String, urlString: String) -> Bool {
    let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
    let encoded =
      standardized.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? standardized
    if urlString.contains(standardized) || urlString.contains(encoded) {
      return true
    }

    // Safari and other cryptex apps are stored under a different absolute path
    // than /System/Applications, but the last path component still matches.
    let fileName = URL(fileURLWithPath: standardized).lastPathComponent
    guard fileName.lowercased().hasSuffix(".app") else { return false }
    let encodedName =
      fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
    return urlString.localizedCaseInsensitiveContains("/\(fileName)")
      || urlString.localizedCaseInsensitiveContains("/\(encodedName)")
  }

  private static func labelMatches(_ fileLabel: String, target: Target) -> Bool {
    if let name = target.name, name.caseInsensitiveCompare(fileLabel) == .orderedSame {
      return true
    }
    let baseName = URL(fileURLWithPath: target.path).deletingPathExtension().lastPathComponent
    return baseName.caseInsensitiveCompare(fileLabel) == .orderedSame
  }

  private static func dockURLString(in tileData: [String: Any]) -> String? {
    if let fileData = tileData["file-data"] as? [String: Any],
      let urlString = fileData["_CFURLString"] as? String
    {
      return urlString
    }
    return nil
  }

  private static func run(_ executable: String, _ arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    try? process.run()
    process.waitUntilExit()
  }

  private static var persistenceURL: URL? {
    FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
      .appendingPathComponent("Tweaker", isDirectory: true)
      .appendingPathComponent("dock-retract.json")
  }

  private static func persist(merging targets: [Target]) {
    save(uniqued(loadPersistedTargets() + targets))
  }

  private static func forget(changes: [SystemApplicationChange]) {
    let bundleIDs = Set(changes.compactMap(\.bundleIdentifier))
    let fileNames = Set(changes.map { URL(fileURLWithPath: $0.sourcePath).lastPathComponent })
    let paths = Set(changes.map(\.sourcePath))
    let remaining = loadPersistedTargets().filter { target in
      if paths.contains(target.path) { return false }
      if fileNames.contains(URL(fileURLWithPath: target.path).lastPathComponent) {
        return false
      }
      if let bundleID = target.bundleIdentifier, bundleIDs.contains(bundleID) {
        return false
      }
      return true
    }
    save(remaining)
  }

  private static func loadPersistedTargets() -> [Target] {
    guard
      let persistenceURL,
      let data = try? Data(contentsOf: persistenceURL),
      let decoded = try? JSONDecoder().decode([Target].self, from: data)
    else {
      return []
    }
    return decoded
  }

  private static func save(_ targets: [Target]) {
    guard let persistenceURL else { return }
    do {
      try FileManager.default.createDirectory(
        at: persistenceURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      if targets.isEmpty {
        try? FileManager.default.removeItem(at: persistenceURL)
        return
      }
      let data = try JSONEncoder().encode(targets)
      try data.write(to: persistenceURL, options: .atomic)
    } catch {
      // Dock cleanup still runs for the current session if the cache cannot be saved.
    }
  }

  private static func uniqued(_ targets: [Target]) -> [Target] {
    var merged: [String: Target] = [:]
    var order: [String] = []
    for target in targets {
      let key = target.bundleIdentifier ?? target.path
      if var existing = merged[key] {
        if existing.bundleIdentifier == nil {
          existing.bundleIdentifier = target.bundleIdentifier
        }
        if existing.name == nil {
          existing.name = target.name
        }
        merged[key] = existing
      } else {
        merged[key] = target
        order.append(key)
      }
    }
    return order.compactMap { merged[$0] }
  }
}
